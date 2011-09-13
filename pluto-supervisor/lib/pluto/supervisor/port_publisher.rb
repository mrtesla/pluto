class Pluto::Supervisor::PortPublisher < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  
  @@subscribers = Set.new
  @@ports       = Set.new
  
  def self.set_port(app, proc, service, port)
    @@ports << [app, proc, service, port]
    
    @@subscribers.each do |sub|
      if subscriber_wants_to_know_port?(sub, app, proc, service)
        chunk = Yajl::Encoder.encode([:set, app, proc, service, port])
        sub.chunked_stream_send(chunk+"\n")
      end
    end
  end
  
  def self.rmv_port(app, proc, service, port)
    @@ports.delete [app, proc, service, port]
    
    @@subscribers.each do |sub|
      if subscriber_wants_to_know_port?(sub, app, proc, service)
        chunk = Yajl::Encoder.encode([:rmv, app, proc, service, port])
        sub.chunked_stream_send(chunk+"\n")
      end
    end
  end
  
  def self.subscriber_wants_to_know_port?(env, application, proc, service)
    if env['params']
      if v = env['params']['application']
        return false if v != application
      end
      
      if v = env['params']['proc']
        return false if v != proc
      end
      
      if v = env['params']['service']
        return false if v != service
      end
    end
    
    return true
  end
  
  def on_close(env)
    env['keepalive'].cancel if env['keepalive']
    @@subscribers.delete(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    @@subscribers << env
    
    EM.next_tick do
      chunk = Yajl::Encoder.encode([:hello])
      env.chunked_stream_send(chunk+"\n")
      
      @@ports.each do |(app, proc, service, port)|
        if self.class.subscriber_wants_to_know_port?(env, app, proc, service)
          chunk = Yajl::Encoder.encode([:set, app, proc, service, port])
          env.chunked_stream_send(chunk+"\n")
        end
      end
    end
    
    env['keepalive'] = EM.add_periodic_timer(5) {
      env.chunked_stream_send('["keepalive"]'+"\n") }

    headers = { 'Content-Type' => 'application/json', 'X-Stream' => 'Goliath' }
    chunked_streaming_response(200, headers)
  end
end