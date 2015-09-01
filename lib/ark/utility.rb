module S25

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
	
	  def root(*args)
	    File.join(Root, *args)
	  end
	end

end # module S25

