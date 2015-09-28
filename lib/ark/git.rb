module ARK

# Methods for getting version numbers and revision hashes from a git
# repository. Version information is extracted from tags, which are expected
# to be in a two number format like +1.5+. The version will have the number of
# revisions since the last tag appended as the minor version; if there have
# been 5 revisions since the last tag, then +1.5+ will become +1.5.5+. If
# there are uncomitted changes in the repository, and the +markdev+ argument
# is true, +.dev+ will be appended to the version number.
module Git

  # Raised when trying to get the revision number from a non-repository
  class GitError < RuntimeError
  end

  def self.version_line(path=nil, project: nil, default: nil, markdev: true)
    path = Dir.pwd unless path
    tb = TextBuilder.new()
    v  = self.version(path, default: default, markdev: markdev)
    begin
      r  = self.revision(path)
    rescue GitError
      r = nil
    end
    p  = project ? project : File.basename(path)
    return tb.push(p, v, r).to_s.strip
  end

  def self.version(path=nil, default: nil, markdev: true)
    path = Dir.pwd unless path
    if self.is_repository?(path)
      v = `git -C #{path} describe --tags`.strip.tr('-', '.')
      c = 2 - v.count('.')
      if c > 0
        v = v + ('.0' * c)
      else
        v.sub!(/\.[^\.]+$/, '')
      end
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
    return system("git -C #{path} rev-parse &> /dev/null")
  end

  def self.is_modified?(path)
    path = Dir.pwd unless path
    return !`git -C #{path} status --porcelain`.empty?
  end
end

end # module ARK

