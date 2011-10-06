module Pluto::Disco::Options
  
  def self.parse!(argv=ARGV)
    
    @port     = 3000
    
    OptionParser.new do |opts|
      opts.banner = "Usage: pluto-disco [options]"
    
      opts.on("-p", "--port PORT", Integer,
              "The port for the HTTP API.") do |p|
        @port = p.to_i
      end
      
    end.parse!(argv)
    
  end
  
  class << self
    attr_accessor :port
  end
  
end
