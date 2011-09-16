class Pluto::Supervisor::PortPublisher < Cramp::Action
  self.transport = :chunked
  
  @@subscribers = Set.new
  @@ports       = Set.new
  
  on_start  :subscribe
  on_start  :send_published_ports
  on_finish :unsubscribe
  periodic_timer :keep_connection_alive, :every => 5

  def keep_connection_alive
    render " "
  end
  
  def self.set_port(app, proc, service, port)
    @@ports << [app, proc, service, port]
    
    @@subscribers.each do |sub|
      sub.notify_change(:set, app, proc, service, port)
    end
  end
  
  def self.rmv_port(app, proc, service, port)
    @@ports.delete [app, proc, service, port]
    
    @@subscribers.each do |sub|
      sub.notify_change(:rmv, app, proc, service, port)
    end
  end
  
  def notify_change(type, app, proc, service, port)
    if subscribed_to_service?(app, proc, service)
      chunk = Yajl::Encoder.encode([type, { :app => app, :proc => proc, :service => service, :port => port }])
      render(chunk+"\n")
    end
  end
  
  def subscribed_to_service?(application, proc, service)
    if v = @env['HTTP_X_APP_NAME']
      return false if v != application
    end
    
    if v = @env['HTTP_X_APP_PROC']
      return false if v != proc
    end
    
    if v = @env['HTTP_X_APP_SERVICE']
      return false if v != service
    end
    
    return true
  end
  
  def respond_with
    [200, {'Content-Type' => 'application/json'}]
  end
  
  def subscribe
    @@subscribers << self
  end
  
  def send_published_ports
    @@ports.each do |(app, proc, service, port)|
      notify_change(:set, app, proc, service, port)
    end
  end
  
  def unsubscribe
    @@subscribers.delete(self)
  end
end
