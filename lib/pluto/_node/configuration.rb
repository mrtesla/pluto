class Pluto::Node::Configuration
  
  def node_name
    Pluto.config.node_name
  end
  
  def disco_endpoint
    _config['register']
  end
  
  def services
    [_config['services']].flatten.compact.uniq
  end
  
  def endpoint
    "http://#{node_name}:#{endpoint_port}/"
  end
  
  def endpoint_port
    @endpoint_port ||= Pluto::Ports.grab
  end
  
private
  
  def _config
    @config ||= Pluto.config['pluto-supervisor'] || {}
  end
  
end