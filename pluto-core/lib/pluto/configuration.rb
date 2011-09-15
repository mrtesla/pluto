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
  
  def pluto
    self['pluto'] || {}
  end
  
end
