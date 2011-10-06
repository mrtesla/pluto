class Pluto::Dashboard::API < Sinatra::Base
  register Sinatra::Contrib
  
  
  def self.run
    trap('INT')  { EM.stop }
    trap('TERM') { EM.stop }
    trap('QUIT') { EM.stop }
    
    EM.run do
      port = Pluto::Dashboard::Options.port
    
      @server = Thin::Server.new('0.0.0.0', port, :signals => false)
      @server.app = self
      @server.start
    
      Subscriber.run
      
      @disco = Pluto::Disco::Client.register(
        Pluto::Dashboard::Options.disco,
        Pluto::Dashboard::Options.endpoint,
        Pluto::Dashboard::Options.node,
        '_dashboard',
        :uuid => '_dashboard'
      ).start
    end
  end
  
  
  get '/stream/appls' do
    stream(:keep_open) do |out|
      Subscriber.new(out, env)
    end
  end
  
  
  class Subscriber

    @@appls      = {}
    @@subs       = Set.new
    @last_change = 0
    
    def self.run
      @settings_file = Pathname.new('settings.yml').expand_path
      
      EM.add_periodic_timer(1) do
        update_appls
      end
      
      EM.add_periodic_timer(5) do
        @@subs.each { |sub| sub.keepalive }
      end
    end
    
    def self.update_appls
      mtime = @settings_file.stat.mtime.to_i
      if mtime <= @last_change
        return
      end
      
      appl_ids = Set.new(@@appls.keys)
      
      settings = YAML.load(@settings_file.read)
      settings.each do |node, apps|
        apps.each do |name, config|
          id = "#{node}@#{name}"
          config = config.merge('node' => node, 'name' => name)
          
          if @@appls.key?(id)
            appl_ids.delete(id)
          end
          
          if @@appls[id] != config
            set(id, config)
          end
        end
      end
      
      appl_ids.each do |id|
        rmv(id)
      end
      
      @last_change = mtime
      
    rescue Object => e
      # ignore
      Pluto.logger.error e
    end
    
    def self.set(id, appl)
      @@appls[id] = appl
      @@subs.each { |sub| sub.notify(:set, appl) }
    end
    
    def self.rmv(id)
      appl = @@appls.delete(id)
      @@subs.each { |sub| sub.notify(:rmv, appl) }
    end

    def initialize(stream, conditions={})
      @stream, @conditions = stream, conditions
      
      @@subs << self
      stream.callback { @@subs.delete self }
      stream.errback  { @@subs.delete self }
      
      @@appls.each do |_,appl|
        notify(:set, appl)
      end
    end

    def notify(change, appl)
      if subscribed?(appl)
        @stream << (Yajl::Encoder.encode([change, appl]) + "\n")
      end
    end
    
    def keepalive
      @stream << " "
    end
    
    def subscribed?(appl)
      if v = @conditions['HTTP_X_PLUTO_IF_NODE']
        return false unless v == appl['node']
      end
      
      return true
    end
    
  end
end
