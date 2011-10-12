module Pluto

  require 'pluto/core/version'
  
  autoload :Core,        'pluto/core'
  autoload :Node,        'pluto/node'
  autoload :TaskManager, 'pluto/task_manager'
  autoload :ApplManager, 'pluto/appl_manager'
  autoload :Disco,       'pluto/disco'
  autoload :Dashboard,   'pluto/dashboard'
  autoload :Varnish,     'pluto/varnish'

  # require 'yaml'
  # require 'pathname'
  # require 'etc'
  # 
  # require 'lumberjack'
  # require 'lumberjack_syslog_device'
  # 
  # autoload :Stream,        'pluto/core/stream'
  # autoload :Configuration, 'pluto/core/configuration'
  # autoload :Ports,         'pluto/core/ports'
  # 
  # def self.root
  #   @root ||= begin
  #     path = ENV['BUNDLE_GEMFILE']
  #     path = File.expand_path(path)
  #     path = File.dirname(path)
  #     Pathname.new(path)
  #   end
  # end
  # 
  # def self.config
  #   @configuration ||= Pluto::Configuration.load(root)
  # end
  
  def self.stats
    return nil unless stats?
    @stats ||= begin
      require 'statsd'
      hostport = ENV['PLUTO_STATSD_HOST'].split(':', 2)
      hostname = hostport[0]
      portname = (hostport[1] || 8125).to_i
      Statsd.new(hostname, portname)
    end
  end
  
  def self.stats?
    !!ENV['PLUTO_STATSD_HOST']
  end

  def self.logger
    @logger ||= begin
      require 'lumberjack'
      Lumberjack::Logger.new(STDOUT)
    end
  end

end
