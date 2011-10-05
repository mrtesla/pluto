class Pluto::ApplManager::DashboardEnvAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  def call(env)

    dashboard = Pluto::ApplManager::Dashboard.shared
    conf      = dashboard[env['name']]

    unless conf and conf['environment']
      return env
    end

    conf['environment'].each do |key, val|
      env_export(env, key.to_s, val.to_s)
    end

    return env
  end

end