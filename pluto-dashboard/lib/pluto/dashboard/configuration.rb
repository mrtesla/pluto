class Pluto::Dashboard::Configuration
  
  def reset!
    Pluto.config.reset!
    @applications = @config = nil
  end
  
  def node_name
    Pluto.config.node_name
  end
  
  def disco_endpoint
    _config['register']
  end
  
  def endpoint
    "http://#{node_name}:#{endpoint_port}/"
  end
  
  def endpoint_port
    @endpoint_port ||= Pluto::Ports.grab
  end
  
  def applications
    @applications ||= begin
      applications = {}
      
      _config.each do |node, apps|
        next if node == 'register'
        
        apps.each do |name, config|
          id = "#{name}@#{node}"
          applications[id] = config.dup.merge('node' => node, 'name' => name)
        end
      end
      
      applications
    end
  end
  
private
  
  def _config
    @config ||= (Pluto.config['pluto-dashboard'] || {})
  end
  
end