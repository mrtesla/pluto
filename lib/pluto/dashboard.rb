module Pluto::Dashboard
  
  require 'set'
  require 'optparse'
  require 'yaml'
  require 'yajl'
  require 'eventmachine'
  require 'thin'
  require 'sinatra/base'
  require 'sinatra/contrib'

  autoload :Options, 'pluto/dashboard/options'
  autoload :API,     'pluto/dashboard/api'
  autoload :Client,  'pluto/dashboard/client'
  
end
