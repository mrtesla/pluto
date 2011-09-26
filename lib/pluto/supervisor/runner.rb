class Pluto::Supervisor::Runner
  
  def initialize(argv)
  end
  
  def run
    (Pluto.root + 'pids').mkpath
    
    EM.kqueue = true if EM.kqueue?
    
    EM.error_handler do |e|
      Pluto.logger.error(e)
      exit(1)
    end
    
    EM.run do
      setup_signals
      
      Pluto::Supervisor::Supervisor.shared.start
      
      start_endpoint
    end
  end
  
  def start_endpoint
    port    = Pluto::Supervisor.config.endpoint_port
    @server = Thin::Server.new('0.0.0.0', port,
      :signals => false)
    @server.app = Pluto::Supervisor::PortPublisher
    @server.start
  end
  
  def setup_signals
    trap('INT')  { stop }
    trap('TERM') { stop }
    trap('QUIT') { stop }
  end
  
  def stop
    @server.stop
  end
  
end