require 'thor'
require 'pluto/node'

class Pluto::Node::Task < Thor
  
  class_option :root, :aliases => "-R",
    :type => :string, :default => '.',
    :desc => "Path to the root of a pluto installation"
  
  desc "start", "Start the Pluto task manager."
  def start
    
  end
  
  desc "stop", "Stop the Pluto task manager."
  def stop
    
  end
  
end
