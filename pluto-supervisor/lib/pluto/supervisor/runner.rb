class Pluto::Supervisor::Runner
  
  def initialize(argv)
    @supervisor  = Pluto::Supervisor::Supervisor.new
    @root        = Pluto.root + 'apps'
  end
  
  def run
    $stderr.reopen('/var/log/messages', 'a+')
    $stdout.reopen('/var/log/messages', 'a+')

    EM.kqueue = true if EM.kqueue?
    EM.run do
      setup_signals
      
      analyze_application
      
      EM.add_periodic_timer(5) do
        @supervisor.start_stopped_processes
      end
      
      EM.add_periodic_timer(15, method(:analyze_application))
      
      register_with_disco
      start_endpoint
    end
  end
  
  def analyze_application
    analyzer  = Pluto::Supervisor::ApplicationAnalyser.new(@root)
    processes = analyzer.run
    @supervisor.update(processes)
  end
  
  def register_with_disco
    @disco = Pluto::Supervisor::Disco.new.start
    Pluto::Supervisor::Dashboard.shared.start
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
    @supervisor.stop_all_processes { @server.stop }
  end
  
end