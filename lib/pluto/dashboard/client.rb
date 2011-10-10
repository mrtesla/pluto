class Pluto::Dashboard::Client < Pluto::Core::Stream

  def self.connect(disco, node=nil)
    @shared.stop if @shared
    @shared = new(disco, node).start
  end

  def self.connected?
    !!(@shared and @shared.connected?)
  end

  def self.shared
    @shared
  end

  def initialize(disco, node)
    url = "http://#{disco}/_dashboard/stream/appls"

    if node
      super(url, 'X-Pluto-If-Node' => node)
    else
      super(url)
    end
  end

  def post_connect
    @applications = {}
  end

  def receive_event(type, application)
    case type

    when 'set'
      id = application['name']
      @applications[id] = application
      on_set(application)

    when 'rmv'
      id = application['name']
      @applications.delete(id)
      on_rmv(application)

    end
  end

  def [](name)
    @applications[name] if @applications
  end

  def on_set(application)
  end

  def on_rmv(application)
  end

end
