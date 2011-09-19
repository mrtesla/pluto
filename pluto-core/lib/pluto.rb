module Pluto
  
  require 'yaml'
  require 'pathname'
  require 'etc'
  
  require 'lumberjack'
  require 'lumberjack_syslog_device'
  require 'statsd'
  
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
  
  def self.stats
    @stats ||= Statsd.new(*config.statsd_host)
  end
  
  def self.stats?
    !!config.pluto['statsd']
  end
  
  def self.logger
    @logger ||= begin
      case config.pluto['logger']
      when 'stdout'
        device = STDOUT
      else
        device = Lumberjack::SyslogDevice.new(
          :facility => Syslog::LOG_LOCAL7)
      end
      Lumberjack::Logger.new(device)
    end
  end
  
end
