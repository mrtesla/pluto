class Pluto::Node::ApplicationAnalyser
  
  PROTECTED_ENV_VARS = []
  
  include Pluto::Node::BaseAnalyser
  include Pluto::Node::ProcfileAnalyser
  include Pluto::Node::DashboardConcurrencyAnalyser
  include Pluto::Node::UidGidAnalyser
  include Pluto::Node::RvmAnalyser
  include Pluto::Node::NvmAnalyser
  include Pluto::Node::EnvrcAnalyser
  include Pluto::Node::DashboardEnvAnalyser
  
  def initialize(root=nil)
    super(root || (Pluto.root + 'apps'))
  end

  # def process_buildin_applications
  #   services = Pluto::Node.config.services
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
