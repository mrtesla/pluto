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
    
    (@cache_dir + (env['PLUTO_APPL_UUID'] + '.appl')).open('w+', 0640) do |f|
      f.write(Yajl::Encoder.encode(env))
    end
    
    procs.each do |env|
      (@task_dir + (env['PLUTO_TASK_UUID'] + '.task')).open('w+', 0640) do |f|
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

end
