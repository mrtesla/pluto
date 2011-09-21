require 'pluto/monitor'
require 'yajl'
require 'set'
require 'cramp'
require 'thin'
require 'http_router'

class Pluto::Monitor::Disco < Pluto::Stream

  def initialize
    disco    = Pluto::Monitor.config.disco_endpoint
    name     = Pluto::Monitor.config.node_name
    endpoint = Pluto::Monitor.config.endpoint

    super("http://#{disco}/api/register",
    'X-Service' => Yajl::Encoder.encode(
      'type'     => 'pluto.monitor',
      'name'     => "pluto.monitor.#{name}",
      'endpoint' => endpoint
    ))
  end

end


class Pluto::Monitor::Analyzer

  def initialize(backend=Pluto::Monitor::Backends::Ps)
    @backend   = backend
    @processes = {}
  end
  
  def start
    EM.add_periodic_timer(5) { run }
  end

private

  def run
    exited_pids = []
    new_pids    = []
    stats       = []
    
    last_seen_processes = @processes.dup

    samples = @backend.snapshot
    samples.each do |sample|
      next unless sample

      is_new = false

      stat = last_seen_processes.delete(sample.pid)

      if stat
        stat.time_delta = (sample.time.to_f - stat.time.to_f).round(2)

      else
        stat     = Pluto::Monitor::Stat.new
        stat.pid = sample.pid
        @processes[stat.pid] = stat

        stat.time_delta = 0
        
        is_new = true
        new_pids << sample.pid
      end

      stat.ppid  = sample.ppid
      stat.pgid  = sample.pgid

      stat.rss   = sample.rss
      stat.vsz   = sample.vsz
      stat.time  = sample.time
      
      unless is_new
        stats << {
          :pid        => stat.pid,
          :ppid       => stat.ppid,
          :pgid       => stat.pgid,
          :rss        => stat.rss,
          :vsz        => stat.vsz,
          :time       => stat.time,
          :time_delta => stat.time_delta
        }
      end
    end

    last_seen_processes.each do |_, stat|
      @processes.delete(stat.pid)
      exited_pids << stat.pid
    end
    
    Pluto::Monitor::SubscribeAPI.notify_changes(new_pids, exited_pids, stats)
  end

end

module Pluto::Monitor

  Stat   = Struct.new(:pid, :ppid, :pgid, :time, :rss, :vsz,
                      :time_delta)
  Sample = Struct.new(:pid, :ppid, :pgid, :time, :rss, :vsz)

  module Backends
    module Ps

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

      def self.snapshot
        output = %x[ ps Sax -o pid=,ppid=,pgid=,rss=,vsz=,time= ]

        output.split("\n").map do |line|
          pid, ppid, pgid, rss, vsz, time = *line.split(' ')

          pid  = pid.to_i
          ppid = ppid.to_i
          pgid = pgid.to_i
          rss  = rss.to_i * 1024
          vsz  = vsz.to_i * 1024

          # skip self
          next if Process.pid == ppid

          if time =~ RE_TIME
            time  = 0.0
            time += $4.to_f
            time += $3.to_i * 60
            time += $2.to_i * 3600
            time += $1.to_i * 86400
            time = time.round(2)
          end

          Pluto::Monitor::Sample.new(pid, ppid, pgid, time, rss, vsz)
        end
      end

    end
  end
end

class Pluto::Monitor::SubscribeAPI < Cramp::Action
  self.transport = :chunked
  
  on_start  :subscribe
  on_finish :unsubscribe
  periodic_timer :keep_connection_alive, :every => 5

  @@subscriptions = Set.new

  def subscribe
    @@subscriptions << self
  end

  def unsubscribe
    @@subscriptions.delete(self)
  end
  
  def self.notify_changes(new_pids, exited_pids, stats)
    @@subscriptions.each do |sub|
      sub.notify_changes(new_pids, exited_pids, stats)
    end
  end
  
  def notify_changes(new_pids, exited_pids, stats)
    chunk = Yajl::Encoder.encode([new_pids, exited_pids, stats])
    render(chunk+"\n")
  end

  def keep_connection_alive
    render " "
  end
end

class Pluto::Monitor::Server

  def run
    routes = HttpRouter.new do
      get('/api/subscribe').to(Pluto::Monitor::SubscribeAPI)
    end

    EM.error_handler do |e|
      Pluto.logger.error(e)
      exit(1)
    end

    EM.next_tick do
      @disco    = Pluto::Monitor::Disco.new.start
      @analyzer = Pluto::Monitor::Analyzer.new.start
    end

    Rack::Handler::Thin.run routes,
      :Port => Pluto::Monitor.config.endpoint_port
  end

end
