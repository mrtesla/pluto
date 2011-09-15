class Pluto::Supervisor::Disco < Pluto::Stream
  
  def initialize
    disco    = Pluto::Supervisor.config.disco_endpoint
    name     = Pluto::Supervisor.config.node_name
    endpoint = Pluto::Supervisor.config.endpoint
    
    super("http://#{disco}/api/register",
    'X-Service' => Yajl::Encoder.encode(
      'type'     => 'pluto.supervisor',
      'name'     => "pluto.supervisor.#{name}",
      'endpoint' => endpoint
    ))
  end
  
end
