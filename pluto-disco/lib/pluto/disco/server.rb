require 'pluto/disco'
require 'yajl'
require 'set'
require 'cramp'
require 'thin'
require 'http_router'

class Pluto::Disco::Registry
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    @subscriptions = Hash.new { |h,k| h[k] = Set.new }
    @services      = Hash.new
  end
  
  def register(id, service)
    Pluto.logger.info "registered: #{service.inspect}"
    
    @services[id] = service
    
    @subscriptions[service['type']].each do |sub|
      sub.notify_change(:register, service)
    end
    
    @subscriptions[nil].each do |sub|
      sub.notify_change(:register, service)
    end
  end
  
  def get(name)
    @services.values.each do |serv|
      next unless serv['name'] == name
      return serv
    end
    return nil
  end
  
  def unregister(id, service)
    @services.delete(id)
    
    @subscriptions[service['type']].each do |sub|
      sub.notify_change(:unregister, service)
    end
    
    @subscriptions[nil].each do |sub|
      sub.notify_change(:unregister, service)
    end
  end
  
  def subscribe(type, sub)
    @subscriptions[type] << sub
    
    @services.each do |id, service|
      next if type and service['type'] != type
      sub.notify_change(:register, service)
    end
  end
  
  def unsubscribe(type, sub)
    @subscriptions[type].delete(sub)
  end
  
end

class Pluto::Disco::RegisterAPI < Cramp::Action
  self.transport = :chunked
  
  on_start  :register
  on_finish :unregister
  periodic_timer :keep_connection_alive, :every => 5

  def register
    @service = Yajl::Parser.parse(@env['HTTP_X_SERVICE'])
    @id      = [@service['endpoint'], @service['type']].join('#')
    
    Pluto::Disco::Registry.shared.register(@id, @service)
  end
  
  def unregister
    Pluto::Disco::Registry.shared.unregister(@id, @service)
  end

  def keep_connection_alive
    render " "
  end
end

class Pluto::Disco::SubscribeAPI < Cramp::Action
  self.transport = :chunked
  
  on_start  :subscribe
  on_finish :unsubscribe
  periodic_timer :keep_connection_alive, :every => 5

  def subscribe
    @type = @env['HTTP_X_SERVICE_TYPE']
    
    Pluto::Disco::Registry.shared.subscribe(@type, self)
  end

  def unsubscribe
    Pluto::Disco::Registry.shared.unsubscribe(@type, self)
  end
  
  def notify_change(type, service)
    chunk = Yajl::Encoder.encode([type, service])
    render(chunk+"\n")
  end

  def keep_connection_alive
    render " "
  end
end

module Pluto::Disco::ConnectAPI
  
  def self.call(env)
    service = env['router.params'][:service]
    service = Pluto::Disco::Registry.shared.get(service)
    unless service
      return [404, {}, ['not found.']]
    end
    
    rest = env['router.params'][:rest]
    url  = [service['endpoint'], rest].flatten.compact.join('/')
    url  = url.gsub('//', '/').sub(':/', '://')
    [302, { 'Location' => url }, []]
  end
  
end

class Pluto::Disco::Server
  
  def run
    routes = HttpRouter.new do
      add('/connect/:service').to(Pluto::Disco::ConnectAPI)
      add('/connect/:service/*rest').to(Pluto::Disco::ConnectAPI)
      get('/api/register').to(Pluto::Disco::RegisterAPI)
      get('/api/subscribe').to(Pluto::Disco::SubscribeAPI)
    end
    
    Rack::Handler::Thin.run routes,
      :Port => Pluto::Disco.config.endpoint_port
  end
  
end
