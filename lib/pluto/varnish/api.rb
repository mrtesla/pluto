class Pluto::Varnish::API < Sinatra::Base
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

      @disco = Pluto::Disco::Client.register(
        Pluto::Dashboard::Options.disco,
        Pluto::Dashboard::Options.endpoint,
        Pluto::Dashboard::Options.node,
        '_varnish'
      ).start

      @task_managers = TaskManagers.subscribe

    end
  end

  def self.update

  end

  class TaskManagers < Pluto::Disco::Client

    def self.subscribe
      super(
        Pluto::Varnish::Options.disco,
        :type => '_task-manager')
    end

    def post_connect
      if @nodes
        @nodes.values.each { |stream| stream.stop }
      end

      @nodes = {}
    end

    def receive_event(type, node)
      case type

      when 'set'
        name = node['name']
        @nodes[name] = # Pluto::Varnish::NodeStream.new(nodes['endpoint']).start

      when 'rmv'
        name = node['name']
        stream = @nodes.delete(name)
        stream.stop if stream

      end
    end

    def each(&blk)
      @nodes.values.each(&blk) if @nodes
    end

  end

  class Dashboard < Pluto::Dashboard::Client

    def self.connect
      super(
        Pluto::Varnish::Options.disco)
    end

    def post_connect
      @appls = {}
    end

    def receive_event(type, application)
      case type

      when 'set'
        id = application['name']
        @appls[id] = application

      when 'rmv'
        id = application['name']
        @appls.delete(id)

      end
    end

    def each(&blk)
      @appls.values.each(&blk) if @appls
    end

  end

end
