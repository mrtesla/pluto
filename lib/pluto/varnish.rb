module Pluto::Varnish

  require 'erb'
  require 'set'
  require 'optparse'
  require 'yaml'
  require 'yajl'
  require 'eventmachine'
  require 'thin'
  require 'sinatra/base'
  require 'sinatra/contrib'

  autoload :Options, 'pluto/varnish/options'
  autoload :API,     'pluto/varnish/api'

end
