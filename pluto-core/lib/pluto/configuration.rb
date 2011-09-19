class Pluto::Configuration < Hash
  
  def self.load(root)
    path = (root + 'config.yml').to_s
    new(path, YAML.load_file(path))
  end
  
  def initialize(path, config)
    super()
    @path = path
    merge! config
  end
  
  def reset!
    clear
    merge! YAML.load_file(@path)
  end
  
  def node_name
    pluto['node'] || 'localhost'
  end
  
  def statsd_host
    @statsd_host ||= begin
      hostport = (pluto['statsd'] || 'localhost:8125').split(':', 2)
      hostname = hostport[0]
      portname = (hostport[1] || 8125).to_i
      [hostport, portname]
    end
  end
  
  def pluto
    self['pluto'] || {}
  end
  
end
