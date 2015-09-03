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

  module Text
    def self.wrap(text, width: 78, indent: 0)
      width -= indent
      text = text.gsub(/\s+/, " ").gsub(/(.{1,#{width}})( |\Z)/, "\\1\n")
      text.gsub(/^/, ' ' * indent)
    end
  end

  class Line
    def initialize()
      @lines = [[]]
      @line  = 0
    end

    def push(str)
      @lines[@line] << str.to_s
    end

    def wrap(text, width: 78, indent: 0)
      text = Text.wrap(text, width: width, indent: indent)
      self.next(text)
      self.next()
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

