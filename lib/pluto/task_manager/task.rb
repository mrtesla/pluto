class Pluto::TaskManager::Task

  class << self
    attr_accessor :supervisor
    attr_writer   :shutdown

    def shutdown?
      @shutdown
    end

    def shutdown_core?
      shutdown? and (begin
        t = @tasks.values
        s = %w( stopped removed crashed )
        t.all? do |t|
          t.env['PLUTO_APPL_NAME'] == 'pluto' or s.include?(t.state)
        end
      end)
    end

    def shutdown_standby?
      t = @tasks.values
      shutdown_core? and (begin
        t = @tasks.values
        s = %w( stopped removed crashed )
        t.all? do |t|
          t.env['PLUTO_PROC_NAME'] == 'task-manager' or s.include?(t.state)
        end
      end)
    end

    def shutdown_self?
      shutdown_standby? and (begin
        t = @tasks.values
        s = %w( stopped removed crashed )
        t.all? do |t|
          s.include?(t.state) or
          (t.env['PLUTO_PROC_NAME'] == 'task-manager' and t.env['PLUTO_PROC_INSTANCE'] == ENV['PLUTO_PROC_INSTANCE'])
        end
      end)
    end
  end

  @tasks    = {}
  @shutdown = false

  state_machine :state, :initial => :stopped do

    after_transition  any          => :starting,    :do => :set_grace_timer
    after_transition  any          => :evaluating,  :do => :set_grace_timer
    after_transition  any          => :terminating, :do => :set_grace_timer
    after_transition  any          => :stopping,    :do => :set_grace_timer
    after_transition  any          => :killing,     :do => :set_grace_timer

    before_transition :starting    => any,          :do => :unset_grace_timer
    before_transition :evaluating  => any,          :do => :unset_grace_timer
    before_transition :terminating => any,          :do => :unset_grace_timer
    before_transition :stopping    => any,          :do => :unset_grace_timer
    before_transition :killing     => any,          :do => :unset_grace_timer

    before_transition any          => :stopped,     :do => :remove_proc_file
    before_transition any          => :crashed,     :do => :remove_proc_file
    before_transition any          => :terminated,  :do => :remove_proc_file

    before_transition any          => :stopped,     :do => :unset_pid
    before_transition any          => :crashed,     :do => :unset_pid
    before_transition any          => :terminated,  :do => :unset_pid

    after_transition  any          => :terminating, :do => :send_term_signal
    after_transition  any          => :stopping,    :do => :send_term_signal
    after_transition  any          => :killing,     :do => :send_kill_signal

    after_transition  any          => :terminated,  :do => :count_exits
    before_transition :stopped     => :starting,    :do => :reset_exits

    after_transition  any          => :starting,    :do => :spawn_process

    after_transition  any          => any,          :do => :update_stat_file
    after_transition  any          => :removed,     :do => :remove_stat_file

    after_transition  :starting    => :running,     :do => :publish_ports
    after_transition  :evaluating  => :running,     :do => :publish_ports
    after_transition  :running     => :stopping,    :do => :unpublish_ports
    after_transition  :running     => :terminating, :do => :unpublish_ports

    after_transition  any          => any,          :do => :publish_task
    after_transition  any          => :removed,     :do => :unpublish_task

    after_transition  do |task, transition|
      task.send(:log, transition)
    end

    event :_tick do
      transition :running => :stopping,    :unless => :enabled?
      transition :running => :terminating, :unless => :proc_file_locked?
      transition :running => :terminating, :unless => :well_behaved?
      # otherwise remain in :running

      transition :terminated => :crashed, :if => :too_many_restarts?
      transition :terminated => :starting

      transition :stopped => :starting, :if => :enabled?
      # otherwise remain in :stopped

      transition :discovered => :evaluating

      transition :evaluating => :terminating, :unless => :proc_file_locked?
      transition :evaluating => :running,     :unless => :within_grace_period?
      # otherwise remain in :evaluating

      transition :starting => :crashed, :unless => :proc_file_locked?
      transition :starting => :running, :unless => :within_grace_period?
      # otherwise remain in :starting

      transition :terminating => :terminated, :unless => :proc_file_locked?
      transition :terminating => :killing,    :unless => :within_grace_period?
      # otherwise remain in :terminating

      transition :stopping => :stopped,  :unless => :proc_file_locked?
      transition :stopping => :killing,  :unless => :within_grace_period?
      # otherwise remain in :stopping

      transition :killing => :crashed, :unless => :proc_file_locked?
      transition :killing => :killing, :unless => :within_grace_period?
      # otherwise remain in :killing

      transition :stopped => :removed, :if => :removed?
      transition :crashed => :removed, :if => :removed?
    end

  end


  RE_FILENAME = /^([0-9a-f]+)\.(?:task|stat|proc)$/

  RE_TIME = /
    ^
    (?:
      (?:(\d+)[-])?
      (\d+)[:]
    )?
    (\d+)[:]
    (\d+(?:[.]\d+)?)
    $
  /x


  def self.tick
    now = Time.new

    ps

    new_uuids = Set.new
    Pluto::TaskManager::Options.data_dir.children.each do |child|
      next unless child.basename.to_s =~ RE_FILENAME
      new_uuids << $1
    end

    old_uuids = Set.new(@tasks.keys)

    (old_uuids - new_uuids).each do |uuid|
      @tasks.delete(uuid)
    end

    (new_uuids - old_uuids).each do |uuid|
      @tasks[uuid] = new(uuid).load
    end

    @tasks.each do |uuid, task|
      task.tick(now)
    end
    
    deliver_stats

    true
  end

  def self.all
    @tasks.values
  end

  def self.deliver_stats
    return unless Pluto.stats?
    
    aggregates = {}
    
    all.each do |task|
      sample = task.sample or next
      env    = task.env    or next
      ns     = [env['PLUTO_APPL_NAME'], env['PLUTO_PROC_NAME']].join('.')
      
      aggregate = aggregates[ns]
      unless aggregate
        aggregate = {
          'mem.rss' => 0,
          'mem.vsz' => 0,
          'cpu'     => 0
        }
        aggregates[ns] = aggregate
      end
      
      aggregate['cpu']     += sample[6]
      aggregate['mem.rss'] += sample[7]
      aggregate['mem.vsz'] += sample[8]
    end
    
    node = Pluto::TaskManager::Options.node.gsub('.', '_')
    
    aggregates.each do |ns, stats|
      stats.each do |stat, count|
        Pluto.stats.count("pluto.#{node}.#{ns}.#{stat}", count)
      end
    end
  end

  def self.boot_supervisor
    return unless @supervisor

    uuid = @supervisor['PLUTO_TASK_UUID']

    task_file = Pluto::TaskManager::Options.data_dir + (uuid + '.task')

    task_file.open('w+', 0640) do |f|
      f.write Yajl::Encoder.encode(@supervisor)
    end

    task = new(uuid).load

    EM.run do
      EM.add_periodic_timer(1) do
        now = Time.new
        task.tick(now)
        EM.stop if task.starting? or task.crashed? or task.removed?
      end
    end
  end

  def self.run_supervisor
    lock_file = Pluto::TaskManager::Options.lock_file
    if locked_file?(lock_file)
      lock_file.open('r') do |f|
        f.flock(File::LOCK_EX)
      end
    end

    f = lock_file.open('w+', 0640)
    f.close_on_exec = false
    f.autoclose     = false
    f.flock(File::LOCK_EX)
    f.puts ENV['PLUTO_TASK_UUID']
    f.flush

    uuid = ENV['PLUTO_TASK_UUID']
    task_file = Pluto::TaskManager::Options.data_dir + (uuid + '.task')
    @supervisor = Yajl::Parser.parse(task_file.read)

    supp = Process.pid

    trap('INT')  { EM.stop }
    trap('TERM') { EM.stop }
    trap('QUIT') { Pluto::TaskManager::Task.shutdown = true }

    EM.run do
      EM.add_periodic_timer(1) { Pluto::TaskManager::Task.tick }
      Pluto::TaskManager::API.run

      @disco = Pluto::Disco::Client.register(
        Pluto::TaskManager::Options.disco,
        Pluto::TaskManager::Options.endpoint,
        Pluto::TaskManager::Options.node,
        '_task-manager'
      ).start
    end
  end

  def self.digest_env(env)
    digest = Digest::SHA1.new
    env.keys.sort.each do |key|
      digest << key.to_s
      digest << env[key].to_s
    end
    digest.hexdigest
  end

  def self.locked_file?(path)
    path = Pathname.new(path) unless Pathname === path

    return false unless path.file?

    path.open('r') do |f|
      f = f.flock(File::LOCK_EX | File::LOCK_NB)
      return (FalseClass === f)
    end
  end

  def initialize(uuid)
    @uuid        = uuid
    @exits       = []

    super()
  end

  def load
    @removed = true
    @enabled = false

    if task_file.file?
      @env = Yajl::Parser.parse(task_file.read)
      @removed = false
      @enabled = true
      @state   = 'stopped'
    end

    if proc_file.file?
      if self.class.locked_file?(proc_file)
        info = Yajl::Parser.parse(proc_file.read)
        @running_env = info['env']
        @pid         = info['pid']
        @ports       = info['ports']
        @state       = 'discovered'
      else
        proc_file.unlink
      end
    end

    if stat_file.file?
      info = nil
      stat_file.open('r') do |f|
        f.flock(File::LOCK_SH)
        info = Yajl::Parser.parse(f.read)
      end
      @enabled     = info['enabled']
      @state       = info['state']
      @exits       = info['exits'].map { |i| Time.at(i) }
      @grace_timer = info['grace_timer']
      @grace_timer = Time.at(@grace_timer) if @grace_timer
    end

    if @state
      publish_ports if @state == 'running'
      publish_task
    end

    if @env
      @env['PLUTO_TASK_UUID'] = @uuid
    end

    self
  end


  attr_writer :enabled
  attr_reader :pid, :env, :sample


  def enabled?
    unless @env['PLUTO_APPL_NAME'] == 'pluto'
      if Pluto::TaskManager::Task.shutdown?
        return false
      else
        return @enabled
      end
    end

    unless @env['PLUTO_PROC_NAME'] == 'task-manager'
      if Pluto::TaskManager::Task.shutdown_core?
        return false
      else
        @enabled
      end
    end

    if @env['PLUTO_PROC_INSTANCE'] == ENV['PLUTO_PROC_INSTANCE']
      return !Pluto::TaskManager::Task.shutdown_self?
    else
      return !Pluto::TaskManager::Task.shutdown_standby?
    end
  end

  def removed?
    @removed
  end

  def tick(now)
    @now = now

    check_task_file
    check_proc_file

    _tick
  end

  def update_stats(sample)
    @sample = sample
  end


  def inspect
    "#<Pluto::TaskManager::Task: #{@env['PLUTO_TASK_UUID']}[#{state}] #{@env['PLUTO_TASK_CMD']}"+
    (@pid ? " pid:#{@pid}" : "none")+
    ">"
  end


private


  def task_file
    @task_file ||= Pluto::TaskManager::Options.data_dir + (@uuid + '.task')
  end

  def stat_file
    @stat_file ||= Pluto::TaskManager::Options.data_dir + (@uuid + '.stat')
  end

  def proc_file
    @proc_file ||= Pluto::TaskManager::Options.data_dir + (@uuid + '.proc')
  end


  def proc_file_locked?
    @proc_file_locked
  end

  def too_many_restarts?
    (@exits.size >= 3) and (@exits.first >= (@now - 600))
  end

  def well_behaved?
    return true unless @sample

    if @sample[7] >= (250 * 1024 * 1024) # rss
      return false
    end

    true # for now
  end

  def within_grace_period?
    @now <= @grace_timer
  end


  def check_proc_file
    @proc_file_locked = self.class.locked_file?(proc_file)
  end

  def check_task_file
    return if task_file.file?
    return if @removed

    @enabled = false
    @removed = true
    update_stat_file
  end

  def remove_proc_file
    proc_file.unlink if proc_file.file?
    @proc_file_locked = false
  end

  def remove_stat_file
    stat_file.unlink if stat_file.file?
  end

  def unset_pid
    @pid = nil
  end

  def set_grace_timer
    @grace_timer = (@now + 30) # 30 seconds
  end

  def unset_grace_timer
    @grace_timer = nil
  end

  def spawn_process
    env   = {}
    ports = {}

    @env.each do |key, val|
      val = val.gsub(/[$]PORT(?:_([a-zA-Z][a-zA-Z0-9_]*))?/) do
        service = ($1 || 'http').downcase
        ports[service] ||= grab_port
        port = ports[service]
        port.to_s
      end

      env[key] = val
    end

    env['PLUTO_TASK_UUID'] = @uuid

    pp_r, pp_w = IO.pipe

    tmp_pid = Process.fork do
      Process.setsid

      if Etc.getpwuid(Process.uid).name == 'root' and env['USER'] != 'root'
        Process.gid  = Etc.getpwnam(env['USER']).gid
        Process.egid = Etc.getpwnam(env['USER']).gid
        Process.uid  = Etc.getpwnam(env['USER']).uid
        Process.euid = Etc.getpwnam(env['USER']).uid
      end

      pid = Process.fork do
        proc_file.dirname.mkpath

        proc_file.open('w+', 0640) do |f|
          f.write(Yajl::Encoder.encode({
            'pid'   => Process.pid,
            'env'   => env,
            'ports' => ports
          }))
        end

        f = proc_file.open('r')
        f.close_on_exec = false
        f.autoclose     = false
        f.flock(File::LOCK_EX)

        pp_w.puts Process.pid

        log_file = '/dev/null'
        log_file = '/var/log/messages'  if File.file?('/var/log/messages')
        if File.file?('tmp/supervisor.log')
          log_file = File.expand_path('tmp/supervisor.log')
          log_file = [log_file, 'a']
        end

        Process.exec(
          env,
          env['PLUTO_TASK_CMD'],
          :pgroup          => true,
          :unsetenv_others => true,
          :chdir           => env['PWD'],
          :umask           => 022,
          :close_others    => true,
          0 => ['/dev/null', 'r'],
          1 => log_file,
          2 => log_file,
          f.fileno => f.fileno
        )
      end

      Process.detach(pid)
    end

    @pid         = pp_r.gets.to_i
    @running_env = env
    @ports       = ports

    Process.waitpid(tmp_pid)

    check_proc_file
  end

  def grab_port
    socket = TCPServer.new('0.0.0.0', 0)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    Socket.do_not_reverse_lookup = true
    port = socket.addr[1]
    socket.close
    return port
  end

  def send_term_signal
    Process.kill('TERM', @pid) if @pid and proc_file_locked?
  end

  def send_kill_signal
    Process.kill('-KILL', @pid) if @pid and proc_file_locked?
  end

  def count_exits
    @exits.push @now
    @exits.shift if @exits.size > 3
  end

  def reset_exits
    @exits = []
  end

  def update_stat_file
    stat_file.open('w+', 0640) do |f|
      f.flock(File::LOCK_EX)
      f.write(Yajl::Encoder.encode({
        'enabled'     => @enabled,
        'state'       => @state,
        'grace_timer' => (@grace_timer ? @grace_timer.to_i : nil),
        'exits'       => @exits.map { |i| i.to_i }
      }))
    end
  end

  def self.ps
    output = %x[ ps Sax -o pid=,ppid=,pgid=,rss=,vsz=,time= ]

    old_process_times = (@process_times || {})
    @process_times = {}

    stats = {}
    stats_order = []

    output.split("\n").each do |line|
      pid, ppid, pgid, rss, vsz, time = *line.split(' ')

      pid  = pid.to_i
      ppid = ppid.to_i
      pgid = pgid.to_i
      rss  = rss.to_i * 1024
      vsz  = vsz.to_i * 1024

      if time =~ RE_TIME
        time  = 0.0
        time += $4.to_f
        time += $3.to_i * 60
        time += $2.to_i * 3600
        time += $1.to_i * 86400
        time = (time * 1000).to_i
      end

      time_delta = 0
      @process_times[pid] = time

      if process_time = old_process_times[pid]
        time_delta = (time - process_time)
      end

      stats[pid] = [ppid, pgid, time, time_delta, rss, vsz,
                                      time_delta, rss, vsz]

      stats_order << pid
    end

    stats_order.reverse_each do |pid|
      current = stats[pid]
      ppid    = current[0]

      next if ppid == pid # don't sum to self
      next if ppid == 0

      parent  = stats[ppid]
      parent[6] += current[6] # time_delta
      parent[7] += current[7] # rss
      parent[8] += current[8] # vsz
    end

    @tasks.each do |uuid, task|
      next unless task.pid
      task.update_stats(stats[task.pid])
    end
  end

  def log(t)
    tag = [@uuid, (@pid || 'none'), (@running_env || @env || {})['PLUTO_TASK_CMD']]
    tag = tag.compact.join(' - ')
    puts "[#{tag}] moved from '#{t.from}' to '#{t.to}'"
  end

  def publish_task
    return unless @env

    task = {
      'uuid' => @uuid,
      'appl' => @env['PLUTO_APPL_NAME'],
      'proc' => @env['PLUTO_PROC_NAME'],
      'instance' => @env['PLUTO_PROC_INSTANCE'],
      'state' => @state
    }
    Pluto::TaskManager::API::TaskSubscriber.set(task)
  end

  def unpublish_task
    Pluto::TaskManager::API::TaskSubscriber.rmv(@uuid)
  end

  def publish_ports
    return unless @env
    return unless @ports

    @ports.each do |serv, port|
      port = [
        @env['PLUTO_APPL_NAME'],
        @env['PLUTO_PROC_NAME'],
        serv,
        port,
        @env['PLUTO_PROC_ORDER']
      ]

      Pluto::TaskManager::API::PortSubscriber.set(port)
    end
  end

  def unpublish_ports
    return unless @ports

    @ports.each do |serv, port|
      port = [
        @env['PLUTO_APPL_NAME'],
        @env['PLUTO_PROC_NAME'],
        serv,
        port,
        @env['PLUTO_PROC_ORDER']
      ]

      Pluto::TaskManager::API::PortSubscriber.rmv(port)
    end
  end

end
