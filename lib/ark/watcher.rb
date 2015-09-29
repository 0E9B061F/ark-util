require 'pathname'

module ARK

class Watcher

  class InvalidHookError < ArgumentError
  end

  class PathInfo
    def initialize(path)
      @path = path
      @mtime = path.mtime
      self.get_type
    end
    attr_reader :path
    attr_reader :mtime
    attr_reader :type

    def get_type
      if @path.symlink?
        @type = :symlink
      elsif @path.directory?
        @type = :directory
      elsif @path.file?
        @type = :file
      else
        @type = :other
      end
    end
  end

  class Event
    def initialize(pathinfo, name)
      @pathinfo = pathinfo
      @name = name
    end
    attr_reader :pathinfo
    attr_reader :name
  end

  ValidEvents = [:any, :created, :modified, :deleted]
  ValidTypes  = [:any, :file, :directory, :symlink, :other]

  def initialize(dir)
    @dir = Pathname.new(dir)
    raise ArgumentError unless @dir.directory?
    @paths = {}
    @hooks = {}
    ValidEvents.each do |e|
      @hooks[e] = {}
      ValidTypes.each do |t|
        @hooks[e][t] = []
      end
    end
    @pid = false
  end


  private

  def daemon
    @pid = Process.fork do
      Signal.trap('INT') { exit 0 }
      refresh
      while true
        scan
        sleep 1
      end
    end
  end

  def scan
    events = []
    rolling_list = []

    # find events
    
    @dir.find do |path|
      if !path.basename.to_s[/^\./].nil?
        Find.prune
      else
        if @paths[path].nil?
          events << Event.new(PathInfo.new(path), :created)
        elsif path.mtime > @paths[path].mtime
          events << Event.new(@paths[path], :modified)
        end
        rolling_list << path
      end
    end

    @paths.keys.each do |path|
      unless rolling_list.member?(path)
        events << Event.new(@paths[path], :deleted)
      end
    end

    # run hooks on events

    unless events.empty?
      events.each {|e| run_hook(e) }
      refresh
    end
  end

  def run_hook(event)
    e = event.name
    t = event.pathinfo.type
    raise InvalidHookError unless ValidEvents.member?(e)
    hooks = @hooks[e][t] + @hooks[:any][t] + @hooks[e][:any]
    hooks.uniq.each {|h| h.call(event.pathinfo.path, e, t) }
  end

  def refresh
    @paths = {}
    @dir.find do |path|
      if !path.basename.to_s[/^\./].nil?
        Find.prune
      else
        @paths[path] = PathInfo.new(path)
      end
    end
  end

  def parse_condition(c)
    e, t = c.to_s.split.map(&:to_sym)
    t = :any unless t
    raise InvalidHookError unless ValidEvents.member?(e)
    raise InvalidHookError unless ValidTypes.member?(t)
    return e, t
  end


  public

  def hook(*conditions, &block)
    conditions.each do |c|
      e, t = parse_condition(c)
      @hooks[e][t] << block
    end
  end

  def begin
    unless @pid
      daemon
      Signal.trap('INT') { self.stop }
      Process.wait
    end
  end

  def stop
    if @pid
      Process.kill('INT', @pid)
      @pid = false
    end
  end

end

end # module ARK

