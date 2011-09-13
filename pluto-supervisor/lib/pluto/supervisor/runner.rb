class Pluto::Supervisor::Runner
  
  def initialize(argv)
    @goliath     = Goliath::Runner.new(argv, nil)
    @goliath.app = Pluto::Supervisor::PortPublisher.new
    @supervisor  = Pluto::Supervisor::Supervisor.new
    @root        = File.expand_path('~/.pluto')
  end
  
  def run
    EM.kqueue = true if EM.kqueue?
    EM.next_tick do
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
    end
    @goliath.run
  end
  
end