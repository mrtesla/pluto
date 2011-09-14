class Pluto::Configuration < Hash
  
  def self.load(root)
    new YAML.load_file(root + 'config.yml')
  end
  
  def initialize(config)
    super()
    merge! config
  end
  
  def node_name
    self['node'] || 'localhost'
  end
  
end
