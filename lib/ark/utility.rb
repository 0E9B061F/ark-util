# ark-util - utility library for ark-* gems
# Copyright 2015 Macquarie Sharpless <macquarie.sharpless@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


module Ark

  # A stopwatch-like timer
  class Timer
    # Configuration details for Ark::Timer. Settings:
    # [+:round+] Number of places to round the returned time to
    Conf = {}
    Conf[:round] = 2

    # Reset the timer start time to now
    def self.reset()
      @@start = Time.now
    end

    # Return the time in seconds from the last call to #reset, or from the
    # beginning of program execution
    def self.time()
      t = Time.now - @@start
      t.round(Conf[:round]).to_s.ljust(5,'0')
    end

    reset

  end

  # Logging/messaging facilities intended for STDOUT
  module Log
    # Configuration details for Ark::Log. Settings:
    # [+:quiet+] Suppress all messages of any verbosity
    # [+:verbose+] Allow high-verbosity messages to be printed
    # [+:timed+] Include the time since Timer#reset was called in all messages
    Conf = {}
    Conf[:quiet] = false
    Conf[:verbose] = false
    Conf[:timed] = true

    # Write +msg+ to standard output according to verbosity settings. Not meant
    # to be used directly
    def say(msg, sym='...', loud=false, indent=0)
      return false if Conf[:quiet]
      return false if loud && !Conf[:verbose]
      unless msg == ''
        time = ""
        if Conf[:timed]
          time = Timer.time.to_s.ljust(4, '0')
          time = time + " "
        end
        indent = "    " * indent
        indent = " " if indent == ""
        puts "#{time}#{sym}#{indent}#{msg}"
      else
        puts
      end
    end
    # Write a low-verbosity message to STDOUT
    def msg(str, indent=0)
      say(str, '>>>', false, indent)
    end
    # Write high-verbosity debugging information to STDOUT
    def dbg(str, indent=0)
      say(str, '...', true, indent)
    end
    # Write a high-verbosity warning to STDOUT
    def wrn(str, indent=0)
      say(str, '???', true, indent)
    end

    # Pulse a message for the duration of the execution of a block
    def pulse(str, time, &block)
      # TODO
    end
  end

  # Methods for manipulating text
  module Text
    
    def self.wrap_segments(segments, width: 78, indent: 0, indent_after: false)
      segments = segments.flatten.map(&:to_s)
      lines = []
      line = ''
      current_indent = indent
      segments.each do |seg|
        if lines.empty? && indent_after
          current_indent = 0
        else
          current_indent = indent
        end
        if line.size + seg.size >= width
          lines << line
          line = (' ' * indent) + seg
        elsif line.empty?
          line = (' ' * current_indent) + seg
        else
          line << ' ' << seg
        end
      end
      lines << line if line
      return lines.join("\n")
    end

    # Wrap a string to a given width, with an optional indent. Indented text
    # will fall within the specified width.
    # [+text+] The text to be wrapped
    # [+width+] The number of columns to wrap within
    # [+indent+] Indent each wrapped line of +text+ by this number of columns
    def self.wrap(text, width: 78, indent: 0, indent_after: false)
      if text.is_a?(Array)
        text = text.flatten.join(' ')
      end
      text = text.split(' ')
      self.wrap_segments(text, width: width, indent: indent, indent_after: indent_after)
    end
  end

  # Build text progressively, line by line
  class TextBuilder
    # Initialize a TextBuilder instance
    def initialize()
      @lines = [[]]
      @line  = 0
    end

    # Push one or more strings onto the current line
    def push(*str)
      @lines[@line] += str.flatten.compact.map(&:to_s)
      return self
    end

    # Concatenate any strings given, then append them to the last element on the
    # line. No spaces will be added before or between the given strings.
    def add(*str)
      @lines[@line][-1] += str.flatten.compact.join
      return self
    end

    # Wrap the current line to +width+, with an optional +indent+. After
    # wrapping, the current line will be the last line wrapped.
    def wrap(width: 78, indent: 0, indent_after: false, segments: false)
      if segments
        text = Text.wrap_segments(@lines[@line], width: width, indent: indent, indent_after: indent_after)
      else
        text = Text.wrap(@lines[@line], width: width, indent: indent, indent_after: indent_after)
      end
      @lines.delete_at(@line)
      @line -= 1
      text.split("\n").each {|line| self.next(line) }
      return self
    end

    # Indent the current line by +count+ columns
    def indent(count)
      @lines[@line].unshift(' ' * (count - 1))
      return self
    end

    # Start a new line. If +str+ is provided, push +str+ onto the new line
    def next(str=nil)
      @lines << []
      @line  += 1
      self.push(str) if str
      return self
    end

    # Insert a blank line and start the line after it. If +str+ is given, push
    # +str+ onto the new line.
    def skip(str=nil)
      self.next()
      self.next(str)
      return self
    end

    # Print the constructed text
    def print()
      return @lines.map {|line| line.join(' ') }.join("\n")
    end

    # Synonym for #print
    def to_s()
      return self.print
    end
  end

  # Methods for getting version numbers and revision hashes from a git
  # repository. Version information is extracted from tags, which are expected
  # to be in a two number format like +1.5+. The version will have the number of
  # revisions since the last tag appended as the minor version; if there have
  # been 5 revisions since the last tag, then +1.5+ will become +1.5.5+. If
  # there are uncomitted changes in the repository, and the +markdev+ argument
  # is true, +.dev+ will be appended to the version number.
  module Git

    def self.version_line(path=nil, project: nil, default: nil, markdev: true)
      path = Dir.pwd unless path
      tb = TextBuilder.new()
      v  = self.version(path, default: default, markdev: markdev)
      r  = self.revision(path)
      p  = project ? project : File.basename(path)
      return tb.push(p, 'v').add(v).push(r).to_s.strip
    end

    def self.version(path=nil, default: nil, markdev: true)
      path = Dir.pwd unless path
      if self.is_repository?(path)
        v = `git -C #{path} describe --tags`.strip.tr('-', '.')
        v.sub!(/\.[^\.]+$/, '')
        if markdev && !`git -C #{path} status --porcelain`.empty?
          v = v + '.dev'
        end
      elsif default
        v = default
      else
        raise GitError, "Cannot get version information; '#{path}' is not a repository and no default value was given."
      end
      return v
    end

    def self.revision(path)
      path = Dir.pwd unless path
      if self.is_repository?(path)
        return `git -C #{path} rev-parse --short HEAD`
      else
        raise GitError, "Error: '#{path}' is not a git repository; cannot get revision."
      end
    end

    def self.is_repository?(path=nil)
      path = Dir.pwd unless path
      return system("git -C #{path} rev-parse")
    end

    def self.is_modified?(path)
      path = Dir.pwd unless path
      return !`git -C #{path} status --porcelain`.empty?
    end
  end

end

