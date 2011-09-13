class Pluto::Supervisor::Runner
  
  def initialize(argv)
    @supervisor  = Pluto::Supervisor::Supervisor.new
    @root        = File.expand_path('~/.pluto')
  end
  
  def run
    EM.kqueue = true if EM.kqueue?
    EM.run do
      analyzer  = Pluto::Supervisor::ApplicationAnalyser.new(@root)
      processes = analyzer.run
      @supervisor.update(processes)
      
      EM.add_periodic_timer(5) do
        @supervisor.start_stopped_processes
      end
      
      EM.add_periodic_timer(15) do
        analyzer  = Pluto::Supervisor::ApplicationAnalyser.new(@root)
        processes = analyzer.run
        @supervisor.update(processes)
      end
      
      @disco = Pluto::Supervisor::Disco.new('http://localhost:9000/api/register',
        'X-Service' => Yajl::Encoder.encode(
          'type'     => 'pluto.supervisor',
          'name'     => 'Pluto Supervisor',
          'endpoint' => 'http://localhost:300'
        )
      ).start
      
      Rack::Handler::Thin.run Pluto::Supervisor::PortPublisher, :Port => 3000
    end
  end
  
end