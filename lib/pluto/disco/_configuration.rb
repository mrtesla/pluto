class Pluto::Disco::Configuration
  
  def node_name
    Pluto.config.node_name
  end
  
  def endpoint
    _config['endpoint']
  end
  
  def endpoint_port
    @endpoint_port ||= endpoint.split(':').last.to_i || 9000
  end
  
private
  
  def _config
    @config ||= Pluto.config['pluto-disco'] || {}
  end
  
end