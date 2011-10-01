class Pluto::Node::ServiceAnalyser
  
  PROTECTED_ENV_VARS = []
  
  include Pluto::Node::BaseAnalyser
  include Pluto::Node::ProcfileAnalyser
  # include Pluto::Node::DashboardConcurrencyAnalyser
  # include Pluto::Node::UidGidAnalyser
  include Pluto::Node::RvmAnalyser
  include Pluto::Node::NvmAnalyser
  include Pluto::Node::EnvrcAnalyser
  # include Pluto::Node::DashboardEnvAnalyser
  
  def initialize(root=nil)
    super(root || (Pluto.root + 'services'))
  end
  
end
