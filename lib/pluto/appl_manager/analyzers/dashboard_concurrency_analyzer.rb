class Pluto::ApplManager::DashboardConcurrencyAnalyzer

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

    unless conf['concurrency']
      return env
    end

    env['PLUTO_CONCURRENCY'].merge!(conf['concurrency'] || {})

    return env
  end

end