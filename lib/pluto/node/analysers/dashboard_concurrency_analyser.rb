class Pluto::Node::DashboardConcurrencyAnalyser

  def call(env)

    dashboard = Pluto::Node::Dashboard.shared
    conf      = dashboard[env['name']]

    unless conf and conf['concurrency']
      return env
    end

    env['concurrency'].merge!(conf['concurrency'] || {})

    return env
  end

end