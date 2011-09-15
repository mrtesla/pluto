class Pluto::Supervisor::Supervisor
  
  def initialize
    @processes          = {}
    @stopping_processes = {}
  end
  
  def update(processes)
    old_processes = @processes.keys
    new_processes = []
    
    processes.each do |env|
      if old_processes.include?(env['SUP_PID'])
        old_processes.delete(env['SUP_PID'])
      else
        new_processes << env
      end
    end
    
    old_processes.each do |pid|
      stop(pid)
    end
    
    new_processes.each do |env|
      process = Process.new(env)
      @processes[env['SUP_PID']] = process
    end
  end
  
  def start_stopped_processes
    @processes.each do |_, process|
      process.start if process.start?
    end
  end
  
  def stop_all_processes(&blk)
    @stop_all_processes_clb = blk if blk
    @processes.each { |k,_| stop(k) }
  end
  
  def stop(pid)
    process = @processes.delete(pid)
    if process
      @stopping_processes[pid] = process
      process.stop do
        @stopping_processes.delete(pid)
        if @stop_all_processes_clb and @stopping_processes.empty?
          @stop_all_processes_clb.call
        end
      end
    end
  end
  
  class Process
    
    def initialize(env)
      @env   = env
      @state = :stopped
      @last_five_exits = []
    end
    
    def start?
      @state == :stopped
    end
    
    def start
      case @state
      when :stopped
        @env_with_ports = build_env_with_ports
        
        @state       = :starting
        @process     = ProcessWatcher.spawn(@env_with_ports, self)
        @start_timer = EM.add_timer(30) { on_running }
        
        Pluto.logger.info "[" + [@env['SUP_APPLICATION'], @env['SUP_PROC'], @env['SUP_INSTANCE']].join(':') + "] starting..."
      else
        # ignore
      end
    end
    
    def stop(&blk)
      case @state
      when :running
        @stop_clb = blk if blk
        @process.shutdown
      when :starting
        @stop_clb = blk if blk
        @process.shutdown
      else
        blk.call
        # ignore
      end
    end
    
    def on_running
      @start_timer = nil
      @state = :running
      
      Pluto.logger.info "[" + [@env['SUP_APPLICATION'], @env['SUP_PROC'], @env['SUP_INSTANCE']].join(':') + "] running..."
      
      # publish ports
      @ports.each do |service, port|
        Pluto::Supervisor::PortPublisher.set_port(@env['SUP_APPLICATION'], @env['SUP_PROC'], service, port)
      end
    end
    
    def on_exit(status)
      now = Time.new
      
      # unpublish ports
      @ports.each do |service, port|
        Pluto::Supervisor::PortPublisher.rmv_port(@env['SUP_APPLICATION'], @env['SUP_PROC'], service, port)
      end
      
      @last_exitstatus = status
      @last_five_exits.unshift now
      if @last_five_exits.size > 5
        @last_five_exits.pop
      end
      
      case @state
      when :starting
        if @start_timer
          EM.cancel_timer(@start_timer)
          @start_timer = nil
        end
        @state = :crashed
      when :running
        if @last_five_exits.size == 5 && @last_five_exits.last >= (now - (10 * 60))
          @state = :crashed
        else
          @state = :stopped
        end
      else
        # ignore
      end
      
    ensure
      @stop_clb.call if @stop_clb
    end
    
    def build_env_with_ports
      env = {}
      
      @ports = {}
      
      @env.each do |key, val|
        val = val.gsub(/[$]PORT_([a-zA-Z][a-zA-Z0-9_]*)/) do
          service = $1.downcase
          @ports[service] ||= Pluto::Ports.grab
          port = @ports[service]
          port.to_s
        end
        
        env[key] = val
      end
      
      env
    end
    
  end
  
  class ProcessWatcher < EM::Connection
    
    P = ::Process
    
    def self.spawn(env, state)
      args = [
        env,
        env['SUP_COMMAND'],
        :pgroup          => true,
        :unsetenv_others => true,
        :chdir           => env['PWD'],
        :umask           => 022,
        :close_others    => true
      ]
      EM.popen("ruby #{File.expand_path('../exec.rb', __FILE__)}", self, args)
    end
    
    def initialize(state, args)
      super()
      @state, @args = state, args
    end
    
    def post_init
      send_data(Yajl::Encoder.encode(@args) + "\n")
    end
    
    def shutdown
      # send TERM
      P.kill('-TERM', pid)
      @kill_timer = EM.add_timer(15, method(:kill))
    end
    
    def kill
      @kill_timer = nil
      
      # send KILL
      P.kill('-KILL', pid)
      @kill_timer = EM.add_timer(15, method(:kill))
    end
    
    def unbind
      EM.cancel_timer(@kill_timer) if @kill_timer
      @state.on_exit(get_status.exitstatus)
    end
    
    def receive_data data
      puts data
    end
    
  end
  
end
