class Pluto::TaskManager::API < Sinatra::Base
  register Sinatra::Contrib
  
  
  def self.run
    port = Pluto::TaskManager::Options.port
    
    @server = Thin::Server.new('0.0.0.0', port, :signals => false)
    @server.app = self
    @server.start
    
    PortSubscriber.run
    TaskSubscriber.run
  end
  
  
  get '/stream/ports' do
    stream(:keep_open) do |out|
      PortSubscriber.new(out, env)
    end
  end
  
  get '/stream/tasks' do
    stream(:keep_open) do |out|
      TaskSubscriber.new(out, env)
    end
  end
  
  
  class PortSubscriber

    @@ports = Set.new
    @@subs  = Set.new
    
    def self.run
      EM.add_periodic_timer(5) do
        @@subs.each { |sub| sub.keepalive }
      end
    end
    
    def self.set(port)
      @@ports << port
      @@subs.each { |sub| sub.notify(:set, port) }
    end
    
    def self.rmv(port)
      @@ports.delete(port)
      @@subs.each { |sub| sub.notify(:rmv, port) }
    end

    def initialize(stream, conditions={})
      @stream, @conditions = stream, conditions
      
      @@subs << self
      stream.callback { @@subs.delete self }
      stream.errback  { @@subs.delete self }
      
      @@ports.each do |port|
        notify(:set, port)
      end
    end

    def notify(change, port)
      if subscribed?(port)
        @stream << (Yajl::Encoder.encode([change, port]) + "\n")
      end
    end
    
    def keepalive
      @stream << " "
    end
    
    def subscribed?(port)
      appl, proc, serv, port = port
      
      if v = @conditions['HTTP_X_PLUTO_IF_APPLICATION']
        return false unless v == appl
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_PROC']
        return false unless v == proc
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_SERVICE']
        return false unless v == serv
      end
      
      return true
    end
    
  end
  
  class TaskSubscriber

    @@tasks = {}
    @@subs  = Set.new
    
    def self.run
      EM.add_periodic_timer(5) do
        @@subs.each { |sub| sub.keepalive }
      end
    end
    
    def self.set(task)
      @@tasks[task['uuid']] = task
      @@subs.each { |sub| sub.notify(:set, task) }
    end
    
    def self.rmv(uuid)
      task = @@tasks.delete(uuid)
      @@subs.each { |sub| sub.notify(:rmv, task) }
    end

    def initialize(stream, conditions={})
      @stream, @conditions = stream, conditions
      
      @@subs << self
      stream.callback { @@subs.delete self }
      stream.errback  { @@subs.delete self }
      
      @@tasks.each do |_, task|
        notify(:set, task)
      end
    end

    def notify(change, task)
      if subscribed?(task)
        @stream << (Yajl::Encoder.encode([change, task]) + "\n")
      end
    end
    
    def keepalive
      @stream << " "
    end
    
    def subscribed?(task)
      if v = @conditions['HTTP_X_PLUTO_IF_APPLICATION']
        return false unless v == appl['appl']
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_PROC']
        return false unless v == proc['proc']
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_INSTANCE']
        return false unless v == serv['instance']
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_STATE']
        return false unless v == serv['state']
      end
      
      return true
    end
    
  end
end
