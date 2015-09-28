require_relative 'timer'

module ARK

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

end # module ARK

