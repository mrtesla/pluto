module Pluto
  
  require 'yaml'
  require 'pathname'
  require 'etc'
  
  require 'lumberjack'
  require 'lumberjack_syslog_device'
  
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
    @logger ||= begin
      device = Lumberjack::SyslogDevice.new
      Lumberjack::Logger.new(device)
    end
  end
  
end
