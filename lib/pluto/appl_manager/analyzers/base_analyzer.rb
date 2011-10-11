class Pluto::ApplManager::BaseAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  PROTECTED_ENV_VARS = %w(
    PATH PWD HOME

    PLUTO_APPL_NAME
    PLUTO_APPL_UUID
    PLUTO_HIDDEN_ENV_VARS
    PLUTO_PROTECTED_ENV_VARS
    PLUTO_CONCURRENCY
    PLUTO_TASKS
  )

  HIDDEN_ENV_VARS = %w(
    PLUTO_HIDDEN_ENV_VARS
    PLUTO_PROTECTED_ENV_VARS
    PLUTO_CONCURRENCY
    PLUTO_PROCFILE
    PLUTO_TASKS
  )

  def call(env)
    env['PLUTO_HIDDEN_ENV_VARS']    = []
    env['PLUTO_PROTECTED_ENV_VARS'] = []
    env['PLUTO_HIDDEN_ENV_VARS'].concat(HIDDEN_ENV_VARS)
    env['PLUTO_PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)

    env['PATH'] = %w(
      /usr/local/bin
      /usr/bin
      /bin
      /usr/local/sbin
      /usr/sbin
      /sbin
    )

    bins = File.expand_path('../../../../../tools/*/bin', __FILE__)
    bins = Dir.glob(bins)
    env['PATH'] = [bins, env['PATH']].flatten

    env['PATH'] = env['PATH'].join(':')
    env['PLUTO_CONCURRENCY'] = {}

    return env
  end

  def process_application_procs
    @processes = []
    @applications.each do |_, env|
      env['procfile'].each do |name, _|
        (env['concurrency'][name] || 1).times do |i|

          proc_env = {}.merge(env)
          proc_env['SUP_PROC'] = name
          proc_env['SUP_INSTANCE'] = (i + 1)
          process_proc_env(proc_env)

          pid_file = Pluto.root + 'pids' + (proc_env['SUP_PID'] + '.pid')
          proc_env['SUP_PID_FILE'] = pid_file.to_s

          @processes << proc_env

        end
      end
    end
  end

  def process_proc_env(env)
    name     = env.delete('name')
    root     = env.delete('root')
    procfile = env.delete('procfile')
    env.delete('concurrency')

    env['SUP_APPLICATION'] = name
    env['PWD']             = root
    env['SUP_COMMAND']     = env_expand(procfile[env['SUP_PROC']], env)

    env.each do |key, value|
      env[key] = value.to_s
    end

    digest = Digest::SHA1.new
    env.keys.sort.each do |key|
      digest << key
      digest << env[key]
    end
    env['SUP_PID'] = digest.hexdigest
  end

end