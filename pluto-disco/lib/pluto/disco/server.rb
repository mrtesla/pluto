require 'goliath'
require 'yajl'
require 'set'

class Pluto::Disco::Registry
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    @subscriptions = Hash.new { |h,k| h[k] = Set.new }
    @services      = Hash.new
  end
  
  def register(id, service)
    @services[id] = service
    
    @subscriptions[service['type']].each do |env|
      message = [:register, service]
      message = Yajl::Encoder.encode(message) + "\n"
      env.chunked_stream_send(message)
    end
  end
  
  def unregister(id, service)
    @services.delete(id)
    
    @subscriptions[service['type']].each do |env|
      message = [:unregister, service]
      message = Yajl::Encoder.encode(message) + "\n"
      env.chunked_stream_send(message)
    end
  end
  
  def subscribe(type, env)
    @subscriptions[type] << env
    
    @services.each do |id, service|
      next unless service['type'] == type
      message = [:register, service]
      message = Yajl::Encoder.encode(message) + "\n"
      env.chunked_stream_send(message)
    end
  end
  
  def unsubscribe(type, env)
    @subscriptions[type].delete(env)
  end
  
end

class Pluto::Disco::RegisterAPI < Goliath::API
  def on_headers(env, headers)
    service = Yajl::Parser.parse(headers['X-Service'])
    id      = [service['endpoint'], service['type']].join('#')
    
    env['disco.service']    = service
    env['disco.service.id'] = id
  end
  
  def on_close(env)
    env['keepalive'].cancel if env['keepalive']
    
    Pluto::Disco::Registry.shared.unregister(
      env['disco.service.id'], env['disco.service'])
  end

  def response(env)
    env['keepalive'] = EM.add_periodic_timer(5) do
      env.chunked_stream_send("[\"keepalive\"]\n")
    end
    
    Pluto::Disco::Registry.shared.register(
      env['disco.service.id'], env['disco.service'])
    
    headers = { 'Content-Type' => 'application/json', 'X-Stream' => 'Goliath' }
    chunked_streaming_response(200, headers)
  end
end

class Pluto::Disco::SubscribeAPI < Goliath::API
  def on_headers(env, headers)
    type = headers['X-Service-Type']
    
    env['disco.service.type'] = type
  end
  
  def on_close(env)
    env['keepalive'].cancel if env['keepalive']
    
    Pluto::Disco::Registry.shared.unsubscribe(
      env['disco.service.type'], self)
  end

  def response(env)
    env['keepalive'] = EM.add_periodic_timer(5) do
      env.chunked_stream_send("[\"keepalive\"]\n")
    end
    
    Pluto::Disco::Registry.shared.subscribe(
      env['disco.service.type'], self)
    
    headers = { 'Content-Type' => 'application/json', 'X-Stream' => 'Goliath' }
    chunked_streaming_response(200, headers)
  end
end

class Pluto::Disco::Server < Goliath::API
  
  get '/api/register' do
    run Pluto::Disco::RegisterAPI.new
  end
  
  get '/api/subscribe' do
    run Pluto::Disco::SubscribeAPI.new
  end
  
end
