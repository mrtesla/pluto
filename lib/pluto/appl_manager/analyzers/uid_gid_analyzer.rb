class Pluto::ApplManager::UidGidAnalyzer

  PROTECTED_ENV_VARS = %w(
    USER
    HOME
  )

  def call(env)
    env['PLUTO_PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)

    if env['PLUTO_APPL_NAME'] == 'pluto'
      env['USER'] ||= ENV['USER']
      u = (Etc.getpwnam(env['USER']) rescue nil)
    else
      env['USER'] ||= 'pluto'
      u = (Etc.getpwnam(env['USER']) rescue nil)
    end

    unless u
      env['USER'] = ENV['USER']
      u = (Etc.getpwnam(env['USER']) rescue nil)
    end

    env['HOME'] = u.dir

    return env
  end

end