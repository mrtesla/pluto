class Pluto::ApplManager::ProcAnalyzer
  
  include Pluto::ApplManager::AnalyzerHelpers

  def call(appl_env)
    concurrency = appl_env['PLUTO_CONCURRENCY']
    procfile    = appl_env['PLUTO_PROCFILE']
    hidden_env  = appl_env['PLUTO_HIDDEN_ENV_VARS']
    
    procs = []
    appl_env['PLUTO_TASKS'] = {}
    
    procfile.each do |proc, command|
      (concurrency[proc] || 1).times do |i|
        
        env = appl_env.dup
        
        hidden_env.each do |var|
          env.delete(var)
        end
        
        env['PLUTO_PROC_NAME']     = proc
        env['PLUTO_PROC_INSTANCE'] = (i + 1).to_s
        env['PLUTO_TASK_CMD']      = env_expand(command, env)
        
        env.each do |key, value|
          env[key] = value.to_s
        end
        
        digest = Digest::SHA1.new
        env.keys.sort.each do |key|
          digest << key
          digest << env[key]
        end
        uuid = digest.hexdigest
        env['PLUTO_TASK_UUID'] = uuid
        
        appl_env['PLUTO_TASKS'][uuid] = "#{proc}-#{i + 1}"
        procs.push(env)
      end
    end
    
    procs
  end

end
