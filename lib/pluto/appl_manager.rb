module Pluto::ApplManager

  require 'set'
  require 'pathname'
  require 'optparse'
  require 'yajl'
  require 'eventmachine'

  require 'pluto/appl_manager/options'
  require 'pluto/appl_manager/appl_analyzer'
  require 'pluto/appl_manager/proc_analyzer'
  require 'pluto/appl_manager/appl_cache'
  require 'pluto/appl_manager/appl_detector'

  def self.run
    @cache    = Pluto::ApplManager::ApplCache.new
    @detector = Pluto::ApplManager::ApplDetector.new(@cache)
    
    EM.run do
      Pluto::Dashboard::Client.connect(
        Pluto::ApplManager::Options.disco,
        Pluto::ApplManager::Options.node)
      
      EM.add_periodic_timer(3) do
        @detector.tick
      end
    end
  end

end
