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

  # Timer.time reports the time since the last call to Timer.reset
  class Timer
    Conf = {}
    Conf[:round] = 2

    def self.reset()
      @@start = Time.now
    end

    def self.time()
      t = Time.now - @@start
      t.round(Conf[:round]).to_s.ljust(5,'0')
    end

    reset

  end

  module Log
    Conf = {}
    Conf[:quiet] = false
    Conf[:verbose] = false
    Conf[:timed] = true

    # Write to standard output according to a standard format and verbosity
    # options
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
    def msg(str, indent=0)
      say(str, '>>>', false, indent)
    end
    def dbg(str, indent=0)
      say(str, '...', true, indent)
    end
    def wrn(str, indent=0)
      say(str, '???', true, indent)
    end

    # Pulse a message for the duration of the execution of a block
    def pulse(str, time, &block)
    end
  end

  # Methods for manipulating text
  module Text
    # Wrap a string to a given width, with an optional indent. Indented text
    # will fall within the specified width.
    # [+text+] The text to be wrapped
    # [+width+] The number of columns to wrap within
    # [+indent+] Indent each wrapped line of +text+ by this number of columns
    def self.wrap(text, width: 78, indent: 0)
      width -= indent
      text = text.gsub(/\s+/, " ").gsub(/(.{1,#{width}})( |\Z)/, "\\1\n")
      text.gsub(/^/, ' ' * indent)
    end
  end

  class TextBuilder
    def initialize()
      @lines = [[]]
      @line  = 0
    end

    def push(str)
      if str.is_a?(Array)
        @lines[@line] += str.map(&:to_s)
      else
        @lines[@line] << str.to_s
      end
    end

    def add(str)
      @lines[@line][-1] += str.to_s
    end

    def wrap(width: 78, indent: 0)
      text = @lines[@line].join(' ')
      text = Text.wrap(text, width: width, indent: indent)
      @lines.delete_at(@line)
      @line -= 1
      text.split("\n").each {|line| self.next(line) }
    end

    def indent(count)
      @lines[@line].unshift(' ' * (count - 1))
    end

    def next(str=nil)
      @lines << []
      @line  += 1
      self.push(str) if str
    end

    def skip(str=nil)
      self.next()
      self.next(str)
    end

    def print()
      @lines.map {|line| line.join(' ') }.join("\n")
    end
  end
end

