class Pluto::ApplManager::ApplDetector

  def initialize(appl_cache)
    @appl_cache = appl_cache
    @dir        = Pluto::ApplManager::Options.appl_dir
  end

  def tick
    uuids   = Set.new(@appl_cache.appl_uuids)
    changed = Pluto::ApplManager::Dashboard.shared.changed

    node_dir = Pathname.new('.').expand_path

    dirs = @dir.children
    dirs.push node_dir
    dirs.each do |child|
      name = child.basename.to_s
      name = 'pluto' if child == node_dir

      unless child.symlink? or child.directory?
        next
      end

      while child.symlink?
        child = child.dirname + child.readlink
      end

      unless child.directory?
        next
      end

      procfile = child + 'Procfile'

      unless procfile.file?
        next
      end

      uuid = Digest::SHA1.hexdigest([
        name,
        child.to_s,
        procfile.stat.mtime.to_s
      ].join("\0"))

      # already have appl
      if uuids.include?(uuid)
        uuids.delete(uuid)
        next unless changed.include?(name)
      end

      # build the default env
      env = {
        'PWD'             => child,
        'PLUTO_APPL_NAME' => name,
        'PLUTO_APPL_UUID' => uuid
      }

      # analyze the app
      env = Pluto::ApplManager::ApplAnalyzer.new.call(env)
      next unless env

      # analyze the procs
      procs = Pluto::ApplManager::ProcAnalyzer.new.call(env)

      # cache the appl and procs
      @appl_cache.store(env, procs)
    end

    # remove the remaining uuids
    uuids.each do |uuid|
      @appl_cache.delete(uuid)
    end
  end

end
