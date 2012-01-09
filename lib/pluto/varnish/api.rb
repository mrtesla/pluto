class Pluto::Varnish::API < Sinatra::Base
  register Sinatra::Contrib


  def self.run
    trap('INT')  { EM.stop }
    trap('TERM') { EM.stop }
    trap('QUIT') { EM.stop }

    EM.run do
      port = Pluto::Varnish::Options.port

      @server = Thin::Server.new('0.0.0.0', port, :signals => false)
      @server.app = self
      @server.start

      @disco = Pluto::Disco::Client.register(
        Pluto::Varnish::Options.disco,
        Pluto::Varnish::Options.endpoint,
        Pluto::Varnish::Options.node,
        '_varnish'
      ).start

      @task_managers = TaskManagers.subscribe
      @dashboard     = Dashboard.connect

      EM.add_periodic_timer(5) do
        update
      end
    end
  end

  def self.update
    backends  = Hash.new { |h,k| h[k] = Set.new }
    frontends = Hash.new { |h,k| h[k] = Set.new }

    @task_managers.each do |task_manager|
      task_manager.each do |(appl, proc, serv, port, order)|
        appl = appl.gsub(/[^a-zA-Z0-9_]+/, '_')
        idx  = order.split(':').index(proc)
        backends[appl] << [task_manager.node, port, idx]
      end
    end

    @dashboard.each do |appl|
      name = appl['name']
      name = name.gsub(/[^a-zA-Z0-9_]+/, '_')

      if appl['alice']
        backends[name] = Set.new
        backends[name] << ['127.0.0.1', 4001, 0]
        backends[name] << ['127.0.0.1', 4002, 0]
        backends[name] << ['127.0.0.1', 4003, 0]
        backends[name] << ['127.0.0.1', 4004, 0]
      end

      next if backends[name].empty?

      hostnames = (appl['hostnames'] || []).dup

      hostnames = hostnames.map do |hostname|
        hostname.to_s.sub(/^www\./, '')
      end

      hostnames.each do |hostname|
        frontends[name] << hostname
      end
    end

    backends.each do |appl, _|
      if frontends[appl].empty?
        backends.delete(appl)
      end
    end

    backends.each do |appl, ports|
      layers = []
      ports.each do |(node, port, idx)|
        layers[idx] ||= []
        layers[idx] << [node, port]
      end
      layers = layers.compact
      backends[appl] = layers
    end

    fallback = Pluto::Varnish::Options.fallback
    if fallback
      fallback = fallback.map do |f|
        f.split(':')
      end
    end

    vcl      = VCL.new(frontends, backends, fallback).render
    vcl_path = Pluto::Varnish::Options.vcl_file
    old_vcl  = ""

    if vcl_path.file?
      old_vcl = vcl_path.read
    end

    if old_vcl == vcl
      return
    end

    vcl_path.open('w+', 0644) do |f|
      f.write vcl
    end

    Kernel.system(Pluto::Varnish::Options.vcl_reload)
  end

  class VCL

    def self.template
      @tpl ||= ERB.new(File.read(File.expand_path('../config.erb', __FILE__)))
    end

    def initialize(frontends, backends, fallback)
      @frontends, @backends, @fallback = frontends, backends, fallback
    end

    def render
      self.class.template.result(binding)
    end

  end

  class TaskManagers < Pluto::Disco::Client

    def self.subscribe
      super(
        Pluto::Varnish::Options.disco,
        :type => '_task-manager').start
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
        name = node['uuid']
        @nodes[name] = PortStream.new(node['endpoint']).start

      when 'rmv'
        name = node['uuid']
        stream = @nodes.delete(name)
        stream.stop if stream

      end
    end

    def each(&blk)
      @nodes.values.each(&blk) if @nodes
    end

  end

  class PortStream < Pluto::Core::Stream

    attr_reader :node

    def initialize(endpoint)
      @node = endpoint.split(':').first
      super "http://#{endpoint}/stream/ports"
    end

    def post_connect
      @ports = Set.new
    end

    def receive_event(type, recd)
      case type

      when 'set'
        appl, proc, serv, port, order = recd
        return if serv != 'http'
        @ports << recd

      when 'rmv'
        @ports.delete(recd)

      end
    end

    def each(&blk)
      @ports.each(&blk) if @ports
    end

  end

  class Dashboard < Pluto::Dashboard::Client

    def self.connect
      super(
        Pluto::Varnish::Options.disco)
    end

    def each(&blk)
      @applications.values.each(&blk) if @applications
    end

  end

end
