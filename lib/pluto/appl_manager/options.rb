module Pluto::ApplManager::Options
  
  def self.parse!(argv=ARGV)
    
    @port      = 3000
    @appl_dir  = Pathname.new('apps').expand_path
    @task_dir  = Pathname.new('tmp/tasks').expand_path
    @cache_dir = Pathname.new('tmp/cache/apps').expand_path
    
    OptionParser.new do |opts|
      opts.banner = "Usage: pluto appl-manager [options]"
    
      opts.on("-p", "--port PORT", Integer,
              "The port for the HTTP API.") do |p|
        @port = p.to_i
      end
    
      opts.on("-a", "--appl-dir DIR",
              "Path to the application directory (default: apps).") do |d|
        @appl_dir = Pathname.new(d || 'apps').expand_path
      end
    
      opts.on("-t", "--task-dir DIR",
              "Path to the task directory (default: tmp/tasks).") do |d|
        @task_dir = Pathname.new(d || 'tmp/tasks').expand_path
      end
    
      opts.on("-c", "--cache-dir DIR",
              "Path to the cache application directory (default: tmp/cache/apps).") do |d|
        @cache_dir = Pathname.new(d || 'tmp/cache/apps').expand_path
      end
      
    end.parse!(argv)
    
  end
  
  class << self
    attr_accessor :port
    attr_accessor :appl_dir
    attr_accessor :task_dir
    attr_accessor :cache_dir
  end
  
end
