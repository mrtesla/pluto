module Pluto
  
  require 'yaml'
  require 'pathname'
  require 'logger'
  
  require 'pluto/version'
  
  autoload :Stream,        'pluto/stream'
  autoload :Configuration, 'pluto/configuration'
  autoload :Ports,         'pluto/ports'
  
  def self.root
    @root ||= begin
      path = ENV['BUNDLE_GEMFILE']
      path = File.expand_path(path)
      path = File.dirname(path)
      Pathname.new(path)
    end
  end
  
  def self.config
    @configuration ||= Pluto::Configuration.load(root)
  end
  
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  
end
