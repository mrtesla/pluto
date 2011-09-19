
class Pluto::Supervisor::Disco < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco    = Pluto::Supervisor.config.disco_endpoint
    name     = Pluto::Supervisor.config.node_name
    endpoint = Pluto::Supervisor.config.endpoint
    
    super("http://#{disco}/api/register",
    'X-Service' => Yajl::Encoder.encode(
      'type'     => 'pluto.supervisor',
      'name'     => "pluto.supervisor.#{name}",
      'endpoint' => endpoint
    ))
  end
  
end


class Pluto::Supervisor::Dashboard < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco    = Pluto::Supervisor.config.disco_endpoint
    name     = Pluto::Supervisor.config.node_name
    
    super("http://#{disco}/connect/pluto.dashboard/api/subscribe",
      'X-Node' => name)
  end
  
  def post_connect
    @applications = {}
  end
  
  def receive_event(type, application)
    case type
      
    when 'set'
      id = application['name']
      @applications[id] = application
      
    when 'rmv'
      id = application['name']
      @applications.delete(id)
      
    end
  end
  
  def [](name)
    @applications[name] if @applications
  end
  
end


class Pluto::Supervisor::Monitor < Pluto::Stream
  
  def self.shared
    @shared ||= new
  end
  
  def initialize
    disco    = Pluto::Supervisor.config.disco_endpoint
    name     = Pluto::Supervisor.config.node_name
    
    super("http://#{disco}/connect/pluto.monitor.#{name}/api/subscribe")
  end
  
  def receive_message(changes)
    handle_changes(*changes)
  end
  
  def handle_changes(new_pids, exited_pids, stats)
    
    # terminate pids we know exited
    exited_pids.each do |pid|
      Pluto::Supervisor::Process.terminated(pid)
    end
    
    # look for more pids that might be missing
    Pluto::Supervisor::Process.each do |process|
      next if stats.any? { |s| s['pid'] == process.pid }
      next if new_pids.include?(process.pid)
      Pluto::Supervisor::Process.terminated(process.pid)
    end
    
    if Pluto.stats?
      # deliver stats
      Pluto::Supervisor::Statistics.new(stats).run
    end
    
  end
  
end

class Pluto::Supervisor::Statistics
  
  def initialize(stats)
    @stats = stats
  end
  
  def run
    aggregate_by_app_and_proc
    deliver_aggregates
  end
  
private

  def aggregate_by_app_and_proc
    @aggregates = {}
    
    @stats.each do |sample|
      process = Pluto::Supervisor::Process[sample['pid']]
      next unless process
      
      ns = [process.app, process.proc].join('.')
      
      aggregate = @aggregates[ns]
      unless aggregate
        aggregate = {
          'mem.rss' => 0,
          'mem.vsz' => 0,
          'cpu'     => 0
        }
        @aggregates[ns] = aggregate
      end
      
      aggregate['mem.rss'] += sample['rss']
      aggregate['mem.vsz'] += sample['vsz']
      aggregate['cpu']     += (sample['time'].to_f / 3600)
    end
  end
  
  def deliver_aggregates
    node = Pluto.config.node_name
    
    @aggregates.each do |ns, stats|
      stats.each do |stat, count|
        Pluto.stats.count("pluto.#{node}.#{ns}.#{stat}", count)
      end
    end
  end
  
end

class Pluto::Supervisor::Supervisor
  
  def self.shared
    @shared ||= new
  end
  
  def start
    Pluto::Supervisor::Process.load_pid_files
    
    Pluto::Supervisor::Disco.shared.start
    Pluto::Supervisor::Dashboard.shared.start
    Pluto::Supervisor::Monitor.shared.start
    
    EM.add_periodic_timer(30, method(:update_process_defintions))
  end
  
  def update_process_defintions
    processes = Pluto::Supervisor::ApplicationAnalyser.new.run
    
    Pluto::Supervisor::Definitions.update(processes)
    Pluto::Supervisor::State.update
  end
  
end

class Pluto::Supervisor::State
  
  @@processes = {}
  
  def self.update
    @@processes.each_key do |sup_pid|
      unless Pluto::Supervisor::Definitions.exists?(sup_pid)
        remove(sup_pid)
      end
    end
    
    Pluto::Supervisor::Definitions.each do |sup_pid, env|
      unless exists?(sup_pid)
        @@processes[sup_pid] = new(sup_pid,
          env['SUP_APPLICATION'],
          env['SUP_PROC'],
          env['SUP_INSTANCE'])
      end
    end
    
    @@processes.each do |_, state|
      state.start if state.start?
    end
  end
  
  def self.remove(sup_pid)
    @@processes[sup_pid].remove
  end
  
  def self.exists?(sup_pid)
    @@processes.key?(sup_pid)
  end
  
  def self.discovered(sup_pid, app, proc, instance)
    @@processes[sup_pid] = new(sup_pid, app, proc, instance)
    @@processes[sup_pid].discovered
  end
  
  def self.started(pid)
    @@processes[pid].started
  end
  
  def self.terminated(pid)
    @@processes[pid].terminated if @@processes[pid]
  end
  
  def initialize(sup_pid, app, proc, instance)
    @sup_pid = sup_pid
    @app, @proc, @instance = app, proc, instance
    @exits = []
    
    @state = :terminated
  end
  
  def start
    return unless start?
    Pluto::Supervisor::Process.spawn(@sup_pid)
  end
  
  def remove
    return if [:stopping, :stopped, :removing, :removed, :starting, :terminated].include?(@state)
    
    @state = :removing
    if has_process?
      Pluto::Supervisor::Process.terminate(@sup_pid)
    else
      removed
    end
  end
  
  def stop
    return if [:stopping, :stopped, :removing, :removed, :starting, :terminated].include?(@state)
    
    @state = :stopping
    if has_process?
      Pluto::Supervisor::Process.terminate(@sup_pid)
    else
      stopped
    end
  end
  
  def started
    @state = :starting
    @running_timer = EM.add_timer(30, method(:running))
  end
  
  def running
    @state = :running
    @running_timer = nil
    
    Pluto::Supervisor::Process.running(@sup_pid)
    
    Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] running..."
  end
  
  def discovered
    @state = :running
    @running_timer = nil
    
    Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] discovered..."
  end
  
  def removed
    @state = :removed
    @@processes.delete(@sup_pid)
    Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] removed..."
  end
  
  def stopped
    @state = :stopped
    Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] stopped..."
  end
  
  def terminated
    if @state == :removing
      removed
      return
    end
    
    if @state == :stopping
      stopped
      return
    end
    
    if @running_timer
      if @exits.size > 2
        crached
        return
      end
    end
    
    now = Time.new
    
    @exits << now
    @exits.shift if @exits.size > 5
    
    if @exits.size == 5 and @exits.first > (now - 600)
      crached
    else
      Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] terminated..."
      @state = :waiting
      @starting_timer = EM.add_timer(30) { @state = :terminated }
    end
    
  ensure
    if @running_timer
      EM.cancel_timer(@running_timer)
      @running_timer = nil
    end
  end
  
  def crached
    @state = :crached
    
    Pluto.logger.info "[" + [@app, @proc, @instance].join(':') + "] crached... (not restarting!)"
  end
  
  def start?
    (@state == :terminated)
  end
  
  def running?
    @state == :running
  end
  
  def has_process?
    Pluto::Supervisor::Process.exists?(@sup_pid)
  end
  
end

module Pluto::Supervisor::Definitions
  
  @@processes = {}
  
  def self.update(processes)
    new_processes = []
    old_processes = @@processes.dup
    
    processes.each do |env|
      sup_pid = env['SUP_PID']
      
      is_new = (old_processes.delete(sup_pid) == nil)
      if is_new
        @@processes[sup_pid] = env
        new_processes << sup_pid
      end
    end
    
    old_processes.each do |sup_pid, env|
      @@processes.delete(sup_pid)
    end
    
    return [new_processes, old_processes.keys]
  end
  
  def self.each(&blk)
    @@processes.each(&blk)
  end
  
  def self.exists?(sup_pid)
    @@processes.key?(sup_pid)
  end
  
  def self.add(env)
    @@processes[env['SUP_PID']] = env
  end
  
  def self.remove(sup_pid)
    @@processes.delete(sup_pid)
  end
  
  def self.[](sup_pid)
    @@processes[sup_pid]
  end
  
  def self.[](sup_pid)
    @@processes[sup_pid]
  end
  
end

class Pluto::Supervisor::Process
  
  @@processes = {}
  @@pids      = {}
  
  P = ::Process
  
  attr_reader :pid, :sup_pid, :app, :proc, :instance
  
  def self.each(&blk)
    @@processes.each_value(&blk)
  end
  
  def self.[](pid)
    if String === pid
      @@processes[pid]
    else
      @@pids[pid]
    end
  end
  
  def self.load_pid_files
    (Pluto.root + 'pids').children.each do |pid_file|
      next unless pid_file.basename.to_s =~ /^(.+)__(.+)__(.+)\.pid$/
      app, proc, instance = $1, $2, $3
      pid, sup_pid, ports = pid_file.read.split("\n", 3)
      pid, sup_pid, ports = pid.to_i, sup_pid.strip, Yajl::Parser.parse(ports)

      process = new(pid, sup_pid, app, proc, instance, ports)
      Pluto::Supervisor::State.discovered(sup_pid, app, proc, instance)
      Pluto::Supervisor::Process.running(sup_pid)
      
      # shoot the monitor in the head
      if app == 'pluto-monitor'
        process.kill
        Pluto::Supervisor::Process.terminated(sup_pid)
      end
      
      # shoot the disco in the head
      if app == 'pluto-disco'
        process.kill
        Pluto::Supervisor::Process.terminated(sup_pid)
      end
    end
  end
  
  def self.build_env_with_ports(o_env)
    env   = {}
    ports = {}
    
    o_env.each do |key, val|
      val = val.gsub(/[$]PORT_([a-zA-Z][a-zA-Z0-9_]*)/) do
        service = $1.downcase
        ports[service] ||= Pluto::Ports.grab
        port = ports[service]
        port.to_s
      end
      
      env[key] = val
    end
    
    return [env, ports]
  end
  
  def self.spawn(sup_pid)
    env = Pluto::Supervisor::Definitions[sup_pid]
    return unless env
    
    pid = @@processes[sup_pid]
    return if pid
    
    Pluto.logger.info "[" + [env['SUP_APPLICATION'], env['SUP_PROC'], env['SUP_INSTANCE']].join(':') + "] starting..."
    
    env, ports = build_env_with_ports(env)
    
    pp_r, pp_w = IO.pipe
    
    tmp_pid = P.fork do
      env.delete('pid_file')
      
      Process.setsid
      
      if File.file?('/var/log/messages')
        $stderr.reopen('/var/log/messages', 'a+')
        $stdout.reopen('/var/log/messages', 'a+')
      end
      
      if Etc.getpwuid(Process.uid).name == 'root' and env['USER'] == 'pluto'
        Process.gid = Etc.getpwnam('pluto').gid
        Process.egid = Etc.getpwnam('pluto').gid
        Process.uid = Etc.getpwnam('pluto').uid
        Process.euid = Etc.getpwnam('pluto').uid
      end
      
      pid = P.spawn(
        env,
        env['SUP_COMMAND'],
        :pgroup          => true,
        :unsetenv_others => true,
        :chdir           => env['PWD'],
        :umask           => 022,
        :close_others    => true
      )
      
      P.detach(pid)
      
      pp_w.puts pid
    end
    
    pid = pp_r.gets.to_i
    P.waitpid(tmp_pid)
    
    File.open(env['pid_file'], 'w+', 0644) do |f|
      f.puts pid
      f.puts env['SUP_PID']
      f.puts Yajl::Encoder.encode(ports)
    end
    
    Pluto::Supervisor::State.started(env['SUP_PID'])
    
    new(pid, env['SUP_PID'], env['SUP_APPLICATION'], env['SUP_PROC'], env['SUP_INSTANCE'], ports)
  end
  
  def self.terminate(sup_pid)
    process = @@processes[sup_pid]
    process.terminate if process
  end
  
  def self.terminated(pid)
    process = (String === pid ? @@processes[pid] : @@pids[pid.to_i])
    process.terminated if process
  end
  
  def self.running(pid)
    process = (String === pid ? @@processes[pid] : @@pids[pid.to_i])
    process.running if process
  end
  
  def self.exists?(sup_pid)
    @@processes.key?(sup_pid)
  end
  
  def initialize(pid, sup_pid, app, proc, instance, ports)
    @pid, @sup_pid = pid.to_i, sup_pid
    @app, @proc, @instance = app, proc, instance
    @ports = ports || {}
    
    @@pids[@pid] = self
    @@processes[sup_pid] = self
  end
  
  def terminate
    P.kill('-TERM', @pid)
    @kill_timer = EM.add_timer(30, method(:kill))
  rescue Errno::ESRCH
    Pluto::Supervisor::State.terminated(@sup_pid)
  end

  def kill
    @kill_timer = nil
    
    # send KILL
    P.kill('-KILL', @pid)
    @kill_timer = EM.add_timer(30, method(:kill))
  rescue Errno::ESRCH
    EM.cancel_timer(@kill_timer) if @kill_timer
    @kill_timer = nil
    Pluto::Supervisor::State.terminated(@sup_pid)
  end
  
  def running
    @ports.each do |service, port|
      Pluto::Supervisor::PortPublisher.set_port(@app, @proc, service, port)
    end
  end
  
  def terminated
    Pluto::Supervisor::State.terminated(@sup_pid)
    
    EM.cancel_timer(@kill_timer) if @kill_timer
    
    @ports.each do |service, port|
      Pluto::Supervisor::PortPublisher.rmv_port(@app, @proc, service, port)
    end
    
    pid_file = Pluto.root + 'pids' + ([@app, @proc, @instance].join('__') + '.pid')
    File.unlink(pid_file) if File.file?(pid_file)
    
    @@pids.delete(@pid)
    @@processes.delete(@sup_pid)
  end
  
end
