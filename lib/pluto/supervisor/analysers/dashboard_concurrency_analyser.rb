module Pluto::Supervisor::DashboardConcurrencyAnalyser
  
private
  
  def process_application(env)
    super(env)
    
    dashboard = Pluto::Supervisor::Dashboard.shared
    conf      = dashboard[env['name']]
    
    return unless conf and conf['concurrency']
    
    env['concurrency'].merge!(conf['concurrency'] || {})
  end
  
end