class Pluto::ApplManager::DashboardConcurrencyAnalyzer

  def call(env)

    dashboard = Pluto::ApplManager::Dashboard.shared
    conf      = dashboard[env['name']]

    unless conf and conf['concurrency']
      return env
    end

    env['concurrency'].merge!(conf['concurrency'] || {})

    return env
  end

end