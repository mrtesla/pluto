class Pluto::Supervisor::ApplicationAnalyser
  
  PROTECTED_ENV_VARS = []
  
  include Pluto::Supervisor::BaseAnalyser
  include Pluto::Supervisor::ProcfileAnalyser
  include Pluto::Supervisor::DashboardConcurrencyAnalyser
  include Pluto::Supervisor::UidGidAnalyser
  include Pluto::Supervisor::RvmAnalyser
  include Pluto::Supervisor::NvmAnalyser
  include Pluto::Supervisor::EnvrcAnalyser
  include Pluto::Supervisor::DashboardEnvAnalyser
  
  def initialize(root=nil)
    super(root || (Pluto.root + 'apps'))
  end

  # def process_buildin_applications
  #   services = Pluto::Supervisor.config.services
  #   
  #   if services.include?('pluto-disco')
  #     env = {
  #       'name'     => 'pluto-disco',
  #       'root'     => Pluto.root,
  #       'procfile' => {
  #         'endpoint' => 'bundle exec pluto disco'
  #       },
  #       'concurrency' => {},
  #       'RUBY_VERSION' => ENV['RUBY_VERSION']
  #     }
  #     
  #     process_default_env(env)
  #     apply_rvm_env(env)
  #     
  #     @applications['pluto-disco'] = env
  #   end
  #   
  #   if services.include?('pluto-dashboard')
  #     env = {
  #       'name'     => 'pluto-dashboard',
  #       'root'     => Pluto.root,
  #       'procfile' => {
  #         'endpoint' => 'bundle exec pluto dashboard'
  #       },
  #       'concurrency' => {},
  #       'RUBY_VERSION' => ENV['RUBY_VERSION']
  #     }
  #     
  #     process_default_env(env)
  #     apply_rvm_env(env)
  #     
  #     @applications['pluto-dashboard'] = env
  #   end
  #   
  #   if services.include?('pluto-varnish')
  #     env = {
  #       'name'     => 'pluto-varnish',
  #       'root'     => Pluto.root,
  #       'procfile' => {
  #         'endpoint' => 'bundle exec pluto varnish'
  #       },
  #       'concurrency' => {},
  #       'RUBY_VERSION' => ENV['RUBY_VERSION']
  #     }
  #     
  #     process_default_env(env)
  #     apply_rvm_env(env)
  #     
  #     @applications['pluto-varnish'] = env
  #   end
  #   
  #   if services.include?('pluto-monitor')
  #     env = {
  #       'name'     => 'pluto-monitor',
  #       'root'     => Pluto.root,
  #       'procfile' => {
  #         'endpoint' => 'bundle exec pluto monitor'
  #       },
  #       'concurrency' => {},
  #       'RUBY_VERSION' => ENV['RUBY_VERSION']
  #     }
  #     
  #     process_default_env(env)
  #     apply_rvm_env(env)
  #     
  #     @applications['pluto-monitor'] = env
  #   end
  # end
  
end
