module ARK

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

end # module ARK

