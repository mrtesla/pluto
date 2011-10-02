class Pluto::Node::BaseAnalyser

  PROTECTED_ENV_VARS = %w(
    name root concurrency
    PATH PWD HOME PROTECTED_ENV_VARS
  )

  def call(env)
    env['PROTECTED_ENV_VARS'] = []
    env['PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)

    env['PATH'] = %w(
      /usr/local/bin
      /usr/bin
      /bin
      /usr/local/sbin
      /usr/sbin
      /sbin
    ).join(':')

    env['concurrency'] = {}

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

  def env_expand(val, env)
    val.gsub(/[$]([a-zA-Z][a-zA-Z0-9_]*)/) do
      var = $1
      if /^PORT_([a-zA-Z][a-zA-Z0-9_]*)$/ =~ var
        "$#{var}"
      else
        env[var] || ''
      end
    end
  end

  def env_export(env, var, val, protect=true)
    if protect and PROTECTED_ENV_VARS.include?(var)
      logger.warn("Not exporting protected ENV ($#{var}) (for .envrc in #{env['root']})")
      return
    end

    expand = true

    if val[0..0] == '"' and val[-1..-1] == '"'
      val = Yajl::Parser.parse(val)
    elsif val[0..0] == "'" and val[-1..-1] == "'"
      val = Yajl::Parser.parse('"'+val[1..-2]+'"')
      expand = false
    end

    if expand
      val = env_expand(val, env)
    end

    env[var] = val
  end

  def env_unset(env, var)
    if PROTECTED_ENV_VARS.include?(var)
      logger.warn("Not unsetting protected ENV ($#{var}) (for .envrc in #{env['root']})")
      return
    end

    env.delete(var)
  end

  def logger
    Pluto.logger
  end

end