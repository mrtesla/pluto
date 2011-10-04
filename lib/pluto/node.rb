module Pluto::Node

  require 'set'
  require 'etc'
  require 'pathname'
  require 'digest/sha1'
  require 'yajl'
  require 'state_machine'
  require 'eventmachine'

  require 'pluto/node/task'

  # require 'yajl'
  # require 'digest/sha1'
  # require 'cramp'
  # require 'thin'
  # 
  # require "pluto/supervisor/application_analyser"
  # require "pluto/supervisor/port_publisher"
  # require "pluto/supervisor/supervisor"
  # require "pluto/supervisor/runner"
  # require "pluto/supervisor/configuration"
  # 
  # def self.config
  #   @config ||= Pluto::Node::Configuration.new
  # end

end
