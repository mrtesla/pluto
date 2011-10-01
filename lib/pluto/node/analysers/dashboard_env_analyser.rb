module Pluto::Node::DashboardEnvAnalyser
  
private
  
  def process_application(env)
    super(env)
    
    dashboard = Pluto::Node::Dashboard.shared
    conf      = dashboard[env['name']]
    
    return unless conf and conf['environment']
    
    conf['environment'].each do |key, val|
      env_export(env, key.to_s, val.to_s)
    end
  end
  
end