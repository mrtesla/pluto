require 'pluto/dashboard'
require 'yajl'
require 'set'
require 'cramp'
require 'thin'
require 'http_router'

class Pluto::Dashboard::Disco < Pluto::Stream
  
  def initialize
    disco    = Pluto::Dashboard.config.disco_endpoint
    endpoint = Pluto::Dashboard.config.endpoint
    
    super("http://#{disco}/api/register",
    'X-Service' => Yajl::Encoder.encode(
      'type'     => 'pluto.dashboard',
      'name'     => "pluto.dashboard",
      'endpoint' => endpoint
    ))
  end
  
end

class Pluto::Dashboard::Registry
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    @subscriptions = Hash.new { |h,k| h[k] = Set.new }
    @applications  = {}
    
    EM.next_tick(method(:reload_configuration))
    EM.add_periodic_timer(15, method(:reload_configuration))
  end
  
  def reload_configuration
    Pluto::Dashboard.config.reset!
    
    unverified_apps = Set.new(@applications.keys)
    
    Pluto::Dashboard.config.applications.each do |id, app|
      unverified_apps.delete(id)
      
      if old_app = @applications[id]
        if old_app == app
          # ignore
        else
          @applications[id] = app
          notify_change(:set, app)
        end
      else
        @applications[id] = app
        notify_change(:set, app)
      end
    end
    
    unverified_apps.each do |id|
      app = @applications.delete(id)
      notify_change(:rmv, app)
    end
    
  ensure
    GC.start
  end
  
  def notify_change(type, app)
    @subscriptions[app['node']].each do |sub|
      sub.notify_change(type, app)
    end
    
    @subscriptions[nil].each do |sub|
      sub.notify_change(type, app)
    end
  end
  
  def subscribe(node, sub)
    @subscriptions[node] << sub
    
    @applications.each do |id, app|
      next if node and node != app['node']
      sub.notify_change(:set, app)
    end
  end
  
  def unsubscribe(node, sub)
    @subscriptions[node].delete(sub)
  end
  
end

class Pluto::Dashboard::SubscribeAPI < Cramp::Action
  self.transport = :chunked
  
  on_start  :subscribe
  on_finish :unsubscribe
  periodic_timer :keep_connection_alive, :every => 5

  def subscribe
    @node = @env['HTTP_X_NODE']
    
    Pluto::Dashboard::Registry.shared.subscribe(@node, self)
  end

  def unsubscribe
    Pluto::Dashboard::Registry.shared.unsubscribe(@node, self)
  end
  
  def notify_change(type, application)
    chunk = Yajl::Encoder.encode([type, application])
    render(chunk+"\n")
  end

  def keep_connection_alive
    render " "
  end
end

class Pluto::Dashboard::Server
  
  def run
    routes = HttpRouter.new do
      get('/api/subscribe').to(Pluto::Dashboard::SubscribeAPI)
    end
    
    EM.error_handler do |e|
      Pluto.logger.error(e)
      exit(1)
    end
    
    EM.next_tick do
      @disco = Pluto::Dashboard::Disco.new.start
    end
    
    Rack::Handler::Thin.run routes,
      :Port => Pluto::Dashboard.config.endpoint_port
  end
  
end
