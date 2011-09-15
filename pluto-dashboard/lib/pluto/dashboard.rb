require "pluto"

module Pluto::Dashboard

  require 'pluto/dashboard/configuration'

  def self.config
    @config ||= Pluto::Dashboard::Configuration.new
  end
  
end
