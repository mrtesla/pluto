class Pluto::ApplManager::DashboardEnvAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  def call(env)
    if env['PLUTO_APPL_NAME'] == 'pluto'
      return env
    end

    unless Pluto::ApplManager::Dashboard.connected?
      return nil
    end

    dashboard = Pluto::ApplManager::Dashboard.shared
    conf      = dashboard[env['PLUTO_APPL_NAME']]

    unless conf
      return nil
    end

    unless conf['environment']
      return env
    end

    conf['environment'].each do |key, val|
      env_export(env, key.to_s, val.to_s)
    end

    return env
  end

end