class Pluto::Supervisor::ServiceAnalyser
  
  PROTECTED_ENV_VARS = []
  
  include Pluto::Supervisor::BaseAnalyser
  include Pluto::Supervisor::ProcfileAnalyser
  # include Pluto::Supervisor::DashboardConcurrencyAnalyser
  # include Pluto::Supervisor::UidGidAnalyser
  include Pluto::Supervisor::RvmAnalyser
  include Pluto::Supervisor::NvmAnalyser
  include Pluto::Supervisor::EnvrcAnalyser
  # include Pluto::Supervisor::DashboardEnvAnalyser
  
  def initialize(root=nil)
    super(root || (Pluto.root + 'services'))
  end
  
end
