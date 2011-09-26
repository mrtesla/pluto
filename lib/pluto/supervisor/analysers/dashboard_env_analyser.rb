module Pluto::Supervisor::DashboardEnvAnalyser
  
private
  
  def process_application(env)
    super(env)
    
    dashboard = Pluto::Supervisor::Dashboard.shared
    conf      = dashboard[env['name']]
    
    return unless conf and conf['environment']
    
    conf['environment'].each do |key, val|
      env_export(env, key.to_s, val.to_s)
    end
  end
  
end