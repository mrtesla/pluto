module Pluto::Disco

  require 'set'
  require 'optparse'
  require 'yajl'
  require 'eventmachine'
  require 'thin'
  require 'sinatra/base'
  require 'sinatra/contrib'

  autoload :Options, 'pluto/disco/options'
  autoload :API,     'pluto/disco/api'
  autoload :Client,  'pluto/disco/client'

end
