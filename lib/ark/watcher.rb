require 'pathname'

module ARK

class Watcher

  class InvalidHookError < ArgumentError
  end

  class PathInfo
    def initialize(path, type)
      @mtime = path.mtime
      @type = type
    end
    attr_reader :mtime
    attr_reader :type
  end

  ValidEvents = [:any, :created, :modified, :deleted]
  ValidTypes  = [:any, :file, :directory, :symlink]

  def initialize(dir)
    @dir = Pathname.new(dir)
    raise ArgumentError unless @dir.directory?
    @paths = {}
    vtypes = ValidTypes.map {|t| [t, []] }
    vhooks = ValidEvents.map {|n| [n, Hash[vtypes]] }
    @hooks = Hash[vhooks]
    @pid = false
    scan first: true
  end


  private

  def daemon
    @pid = Process.fork do
      Signal.trap('INT') { exit 0 }
      while true
        scan
        sleep 1
      end
    end
  end

  def scan(first: false)
    rolling_list = []

    @dir.find do |path|
      if !path.basename.to_s[/^\./].nil?
        Find.prune
      else
        if @paths[path].nil?
          unless first
            run_hook(:created, path)
          end
          @paths[path] = pinfo(path)
        elsif path.mtime > @paths[path].mtime
          run_hook(:modified, path)
          @paths[path] = pinfo(path)
        end
        rolling_list << path
      end
    end

    deleted = @paths.keys - rolling_list
    deleted.each do |path|
      run_hook(:deleted, path)
      @paths.delete(path)
    end
  end

  def run_hook(event, path)
    raise InvalidHookError unless ValidEvents.member?(event)
    type = get_type(path) || @paths[path].type || :any
    hooks = @hooks[event][type] + @hooks[:any][type] + @hooks[event][:any]
    hooks.uniq.each {|h| h.call(path, event, type) }
  end

  def get_type(path)
    if path.symlink?
      type = :symlink
    elsif path.directory?
      type = :directory
    elsif path.file?
      type = :file
    else
      type = false
    end
    return type
  end

  def pinfo(path)
    return PathInfo.new(path, get_type(path))
  end


  public

  def hook(event=:any, type=:any, &block)
    raise InvalidHookError unless ValidEvents.member?(event)
    raise InvalidHookError unless ValidTypes.member?(type)
    @hooks[event][type] << block
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

