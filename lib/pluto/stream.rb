class Pluto::Stream
  
  require 'em-http-request'
  
  DEFAULT_OPTIONS = {
    :connect_timeout    => 5,
    :inactivity_timeout => 10
  }
  
  def initialize(endpoint, headers={}, options={})
    @endpoint = endpoint
    @headers  = headers
    @restart  = true
    
    @options  = DEFAULT_OPTIONS.merge(options)
  end
  
  def start
    return if @req
    
    @req = EventMachine::HttpRequest.new(@endpoint).get(
      :head      => @headers,
      :keepalive => false,
      :redirects => 3)
    
    @parser = Yajl::Parser.new
    @parser.on_parse_complete = method(:_receive_message)
    
    @req.stream do |chunk|
      unless @post_connect_called
        @post_connect_called = true
        post_connect
      end
      
      begin
        @parser << chunk if @parser
      rescue Yajl::ParseError => e
        Pluto.logger.error e unless e.message.include?('not found')
        @req.unbind(e.message)
        @req = @parser = nil
        @post_connect_called = false
      end
    end
    
    @req.callback do |_|
      @req = @parser = nil
      @post_connect_called = false
      EM.add_timer(5) { start if @restart }
    end
    
    @req.errback do |_|
      @req = @parser = nil
      @post_connect_called = false
      EM.add_timer(5) { start if @restart }
    end
    
    self
  end
  
  def stop
    return unless @req
    
    @restart = false
    
    @req.unbind('not interested')
    @req = @parser = nil
    @post_connect_called = false
  end
  
  def _receive_message(message)
    unless Array === message
      receive_message(message)
      return
    end
    
    unless message.size == 2 or message.size == 1
      receive_message(message)
      return
    end
    
    unless String === message[0]
      receive_message(message)
      return
    end
    
    receive_event(message[0], message[1])
  end
  
  def post_connect
    
  end
  
  def receive_message(message)
    
  end
  
  def receive_event(name, data)
    
  end
  
end