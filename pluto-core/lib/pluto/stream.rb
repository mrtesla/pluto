class Pluto::Stream
  
  require 'em-http-request'
  
  DEFAULT_OPTIONS = {
    :connect_timeout    => 5,
    :inactivity_timeout => 10
  }
  
  def initialize(endpoint, headers={}, options={})
    @endpoint = endpoint
    @headers  = headers
    
    @options  = DEFAULT_OPTIONS.merge(options)
  end
  
  def start
    return if @req
    
    @req = EventMachine::HttpRequest.new(@endpoint).get(
      :head      => @headers,
      :redirects => 3)
    
    @req.stream do |chunk|
      message = Yajl::Parser.parse(chunk)
      _receive_message(message)
    end
    
    @req.callback do
      @req = nil
      EM.add_timer(5) { start }
    end
    
    @req.errback do
      @req = nil
      EM.add_timer(5) { start }
    end
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
  
  def receive_message(message)
    
  end
  
  def receive_event(name, data)
    
  end
  
end