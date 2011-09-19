require "pluto"

module Pluto::Supervisor

  require 'yajl'
  require 'digest/sha1'
  require 'cramp'
  require 'thin'

  require "pluto/supervisor/application_analyser"
  require "pluto/supervisor/port_publisher"
  require "pluto/supervisor/supervisor"
  require "pluto/supervisor/runner"
  require "pluto/supervisor/configuration"

  def self.config
    @config ||= Pluto::Supervisor::Configuration.new
  end

end
