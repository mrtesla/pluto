require "pluto"

module Pluto::Varnish

  require 'pluto/varnish/configuration'

  def self.config
    @config ||= Pluto::Varnish::Configuration.new
  end
  
end
