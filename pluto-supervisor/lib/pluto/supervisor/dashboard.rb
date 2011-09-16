class Pluto::Supervisor::Dashboard < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco    = Pluto::Supervisor.config.disco_endpoint
    name     = Pluto::Supervisor.config.node_name
    
    super("http://#{disco}/connect/pluto.dashboard/api/subscribe",
      'X-Node' => name)
  end
  
  def post_connect
    @applications = {}
  end
  
  def receive_event(type, application)
    case type
      
    when 'set'
      id = application['name']
      @applications[id] = application
      
    when 'rmv'
      id = application['name']
      @applications.delete(id)
      
    end
  end
  
  def [](name)
    @applications[name]
  end
  
end
