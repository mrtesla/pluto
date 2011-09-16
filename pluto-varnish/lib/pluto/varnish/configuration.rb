class Pluto::Varnish::Configuration
  
  def node_name
    Pluto.config.node_name
  end
  
  def disco_endpoint
    _config['register']
  end
  
  def fallback_host
    _fallback['host'] || 'localhost'
  end
  
  def fallback_port
    _fallback['port'] || 81
  end
  
  def config_file
    _config['config_file'] || '/etc/varnish/default.vlc'
  end
  
  def reload_cmd
    _config['reload_cmd'] || '/etc/init.d/varnish reload'
  end
  
private
  
  def _config
    @config ||= (Pluto.config['pluto-varnish'] || {})
  end
  
  def _fallback
    _config['fallback'] || {}
  end
  
end