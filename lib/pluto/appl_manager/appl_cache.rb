class Pluto::ApplManager::ApplCache

  def initialize
    @cache_dir = Pluto::ApplManager::Options.cache_dir
    @task_dir  = Pluto::ApplManager::Options.task_dir

    @cache_dir.mkpath
    @task_dir.mkpath
  end

  def appl_uuids
    @cache_dir.children.map do |child|
      next unless child.basename.to_s =~ /^(.+)\.appl$/
      $1
    end.compact
  end

  def store(env, procs)
    uuid = env['PLUTO_APPL_UUID']

    remove_old_tasks(uuid, procs)

    (@cache_dir + (uuid + '.appl')).open('w+', 0640) do |f|
      f.write(Yajl::Encoder.encode(env))
    end

    procs.each do |env|
      uuid = env['PLUTO_TASK_UUID']
      (@task_dir + (uuid + '.task')).open('w+', 0640) do |f|
        f.write(Yajl::Encoder.encode(env))
      end
    end

  end

  def delete(uuid)
    appl_file = (@cache_dir + (uuid + '.appl'))
    return unless appl_file.file?

    appl = Yajl::Parser.parse(appl_file.read)
    appl_file.unlink

    appl['PLUTO_TASKS'].each do |uuid, name|
      task_file = (@task_dir + (uuid + '.task'))
      task_file.unlink if task_file.file?
    end
  end

private

  def remove_old_tasks(uuid, procs)
    appl_file = (@cache_dir + (uuid + '.appl'))
    return unless appl_file.file?

    procs = procs.map { |p| p['PLUTO_TASK_UUID'] }

    appl = Yajl::Parser.parse(appl_file.read)
    appl['PLUTO_TASKS'].each do |uuid, name|
      next if procs.include?(uuid)

      task_file = (@task_dir + (uuid + '.task'))
      task_file.unlink if task_file.file?
    end
  end

end
