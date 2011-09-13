class Pluto::Supervisor::Supervisor
  
  def initialize
    @processes = {}
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
      process = @processes.delete(pid)
      process.stop if process
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
      else
        # ignore
      end
    end
    
    def stop
      case @state
      when :running
        @process.shutdown
      when :starting
        @process.shutdown
      else
        # ignore
      end
    end
    
    def on_running
      @start_timer = nil
      @state = :running
      
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
    end
    
    def build_env_with_ports
      env = {}
      
      @ports = {}
      
      @env.each do |key, val|
        val = val.gsub(/[$]PORT_([a-zA-Z][a-zA-Z0-9_]*)/) do
          service = $1.downcase
          @ports[service] ||= get_ephemeral_port
          port = @ports[service]
          port.to_s
        end
        
        env[key] = val
      end
      
      env
    end
    
    def get_ephemeral_port
      socket = TCPServer.new('0.0.0.0', 0)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      Socket.do_not_reverse_lookup = true
      port = socket.addr[1]
      socket.close
      return port
    end
    
  end
  
  class ProcessWatcher < EventMachine::ProcessWatch
    
    P = ::Process
    
    def self.spawn(env, state)
      pid = P.spawn(
        env,
        env['SUP_COMMAND'],
        :unsetenv_others => true,
        :chdir           => env['PWD'],
        :umask           => 022,
        :close_others    => true
      )
      EM.watch_process(pid, self, state)
    end
    
    def initialize(state)
      super()
      @state = state
    end
    
    def shutdown
      # send TERM
      P.kill('TERM', pid)
      @kill_timer = EM.add_timer(15, method(:kill))
    end
    
    def kill
      @kill_timer = nil
      
      # send KILL
      P.kill('KILL', pid)
      @kill_timer = EM.add_timer(15, method(:kill))
    end
    
    def process_exited
      P.waitpid(pid)
      EM.cancel_timer(@kill_timer) if @kill_timer
      @state.on_exit($?)
    end
    
  end
  
end
