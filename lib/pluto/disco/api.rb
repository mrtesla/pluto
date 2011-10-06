class Pluto::Disco::API < Sinatra::Base
  register Sinatra::Contrib
  
  
  def self.run
    trap('INT')  { EM.stop }
    trap('TERM') { EM.stop }
    trap('QUIT') { EM.stop }
    
    EM.run do
      port = Pluto::Disco::Options.port
    
      @server = Thin::Server.new('0.0.0.0', port, :signals => false)
      @server.app = self
      @server.start
    
      Subscriber.run
      Publisher.run
    end
  end
  
  
  get '/stream/services' do
    stream(:keep_open) do |out|
      Subscriber.new(out, env)
    end
  end
  
  get '/stream/register' do
    stream(:keep_open) do |out|
      Publisher.new(out, env)
    end
  end
  
  get '/:uuid/*' do
    serv = Subscriber.find(params[:uuid])
    unless serv
      halt 404, {'Content-Type' => 'text/plain'}, ''
    end
    
    url = ['http:/', serv['endpoint'], (params[:splat] || '')].join('/')
    redirect url
  end
  
  
  class Subscriber

    @@servs = Set.new
    @@subs  = Set.new
    
    def self.run
      EM.add_periodic_timer(5) do
        @@subs.each { |sub| sub.keepalive }
      end
    end
    
    def self.find(uuid)
      @@servs[uuid]
    end
    
    def self.set(serv)
      @@servs << serv
      @@subs.each { |sub| sub.notify(:set, serv) }
    end
    
    def self.rmv(serv)
      @@servs.delete(serv)
      @@subs.each { |sub| sub.notify(:rmv, serv) }
    end

    def initialize(stream, conditions={})
      @stream, @conditions = stream, conditions
      
      @@subs << self
      stream.callback { @@subs.delete self }
      stream.errback  { @@subs.delete self }
      
      @@servs.each do |serv|
        notify(:set, serv)
      end
    end

    def notify(change, serv)
      if subscribed?(serv)
        @stream << (Yajl::Encoder.encode([change, serv]) + "\n")
      end
    end
    
    def keepalive
      @stream << " "
    end
    
    def subscribed?(serv)
      if v = @conditions['HTTP_X_PLUTO_IF_TYPE']
        return false unless v == serv['type']
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_NODE']
        return false unless v == serv['node']
      end
      
      if v = @conditions['HTTP_X_PLUTO_IF_UUID']
        return false unless v == serv['uuid']
      end
      
      return true
    end
    
  end
  
  class Publisher

    @@pubs = Set.new
    
    def self.run
      EM.add_periodic_timer(5) do
        @@pubs.each { |pub| pub.keepalive }
      end
    end

    def initialize(stream, env={})
      @stream, @env = stream, env
      
      @service = Yajl::Parser.parse(@env['HTTP_X_PLUTO_SERVICE'] || '')
      
      @@pubs << self
      Subscriber.set(@service)
      
      stream.callback do
        Subscriber.rmv(@service)
        @@pubs.delete self
      end
      
      stream.errback do
        Subscriber.rmv(@service)
        @@pubs.delete self
      end
    end
    
    def keepalive
      @stream << " "
    end
    
  end
end
