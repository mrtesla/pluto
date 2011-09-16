require 'pluto/varnish'
require 'yajl'
require 'set'
require 'erb'
require 'digest/sha1'

class Pluto::Varnish::DiscoStream < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco = Pluto::Varnish.config.disco_endpoint
    super("http://#{disco}/api/subscribe",
      'X-Service-Type' => 'pluto.supervisor')
  end
  
  def post_connect
    if @supervisors
      @supervisors.values.each { |stream| stream.stop }
    end
    
    @supervisors = {}
  end
  
  def receive_event(type, supervisor)
    p [type, supervisor]
    
    case type
      
    when 'register'
      name = supervisor['name']
      @supervisors[name] = Pluto::Varnish::SupervisorStream.new(supervisor['endpoint']).start
      
    when 'unregister'
      name = supervisor['name']
      stream = @supervisors.delete(name)
      stream.stop if stream
      
    end
  end
  
  def each(&blk)
    @supervisors.values.each(&blk) if @supervisors
  end
  
end

class Pluto::Varnish::DashboardStream < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco = Pluto::Varnish.config.disco_endpoint
    super("http://#{disco}/connect/pluto.dashboard/api/subscribe")
  end
  
  def post_connect
    @applications = {}
  end
  
  def receive_event(type, application)
    p [type, application]
    
    case type
      
    when 'set'
      id = application['name']
      @applications[id] = application
      
    when 'rmv'
      id = application['name']
      @applications.delete(id)
      
    end
  end
  
  def each(&blk)
    @applications.values.each(&blk) if @applications
  end
  
end

class Pluto::Varnish::SupervisorStream < Pluto::Stream
  
  def initialize(endpoint)
    @node = URI.parse(endpoint).host
    super(endpoint, 'X-App-Proc' => 'web', 'X-App-Service' => 'http')
  end
  
  def post_connect
    @instances = Hash.new { |h,k| h[k] = Set.new }
  end
  
  def receive_event(type, application)
    p [@node, type, application]
    
    case type
      
    when 'set'
      app = application['app']
      @instances[app] << application['port']
      
    when 'rmv'
      app = application['app']
      @instances[app].delete(application['port'])
      @instances.delete(app) if @instances[app].empty?
      
    end
  end
  
  def node
    @node
  end
  
  def [](name)
    (@instances || {})[name] || Set.new
  end
  
end

class Pluto::Varnish::ConfigurationBuilder
  
  def run
    build_fallback
    build_envs
    build_backends
    build_frontends
    
    render_configuration
    compaire_with_original_configuration
    write_configuration
    reload_configuration
  end
  
private

  def build_fallback
    @fallback_host = Pluto::Varnish.config.fallback_host
    @fallback_port = Pluto::Varnish.config.fallback_port
  end

  def build_envs
    @envs = {}
    
    Pluto::Varnish::DashboardStream.shared.each do |app|
      name = app['name']
      next unless name
      
      name = name.gsub(/^[a-zA-Z0-9_]+/, '_')
      
      env = {}
      env['name']      = name
      env['hostnames'] = app['hostnames'] || []
      env['backends']  = []
      
      if Array === app['backends']
        app['backends'].each do |host_port|
          host, port = *host_port.split(':', 2)
          port = port.to_i
          env['backends'] << [host, port]
        end
      end
      
      env['hostnames'] = env['hostnames'].map do |hostname|
        hostname.to_s.sub(/^www\./, '')
      end.uniq.sort.compact
      
      Pluto::Varnish::DiscoStream.shared.each do |supervisor|
        supervisor[app['name']].each do |port|
          env['backends'] << [supervisor.node, port]
        end
      end
      
      next if env['hostnames'].empty?
      next if env['backends'].empty?
      
      @envs[name] = env
    end
  end
  
  def build_backends
    @backends = {}
    
    @envs.each do |name, env|
      @backends[name] = env['backends']
    end
  end
  
  def build_frontends
    @frontends = {}
    
    @envs.each do |name, env|
      env['hostnames'].each do |hostname|
        if @frontends.key?(hostname)
          Pluto.logger.warn("Host #{hostname} is used by two or more applications.")
          next
        end
        
        @frontends[hostname] = name
      end
    end
  end
  
  def render_configuration
    b = binding
    tpl = ERB.new(File.read(File.expand_path('../config.erb', __FILE__)))
    @new_config = tpl.result(b)
  end
  
  def compaire_with_original_configuration
    return unless File.file?(Pluto::Varnish.config.config_file)
    
    old_config = File.read(Pluto::Varnish.config.config_file)
    old_config = Digest::SHA1.hexdigest(old_config)
    new_config = Digest::SHA1.hexdigest(@new_config)
    
    if old_config == new_config
      @no_changes = true
    end
  end
  
  def write_configuration
    return if @no_changes
    
    File.open(Pluto::Varnish.config.config_file, 'w+', 0644) do |f|
      f.write @new_config
    end
  end
  
  def reload_configuration
    return if @no_changes
    
    Kernel.system(Pluto::Varnish.config.reload_cmd)
  end
  
end

class Pluto::Varnish::Server
  
  def run
    EM.run { _run }
  end
  
  def _run
    Pluto::Varnish::DiscoStream.shared.start
    Pluto::Varnish::DashboardStream.shared.start
    
    EM.add_periodic_timer(15) do
      Pluto::Varnish::ConfigurationBuilder.new.run
    end
  end
  
end
