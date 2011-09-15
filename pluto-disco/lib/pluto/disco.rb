require "pluto"

module Pluto::Disco

  require 'pluto/disco/configuration'

  def self.config
    @config ||= Pluto::Disco::Configuration.new
  end
  
end
