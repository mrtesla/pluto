require "pluto"

module Pluto::Monitor

  require 'pluto/monitor/configuration'

  def self.config
    @config ||= Pluto::Monitor::Configuration.new
  end

end
