class Pluto::Node::DashboardEnvAnalyser

  include Pluto::Node::AnalyserHelpers

  def call(env)

    dashboard = Pluto::Node::Dashboard.shared
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