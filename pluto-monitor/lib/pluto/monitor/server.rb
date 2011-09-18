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

private

  def snapshot
    last_seen_processes = @processes.dup

    samples = @backend.snapshot
    samples.each do |sample|
      next unless sample

      stat = last_seen_processes.delete(sample.pid)

      if stat
        stat.utime_delta = sample.utime - stat.utime
        stat.stime_delta = sample.stime - stat.stime

      else
        stat     = Pluto::Monitor::Stat.new
        stat.pid = sample.pid
        @processes[stat.pid] = stat

        stat.utime_delta = 0
        stat.stime_delta = 0

        puts "[PID: #{stat.pid}] started"
      end

      stat.ppid  = sample.ppid
      stat.pgid  = sample.pgid

      stat.rss   = sample.rss
      stat.vsz   = sample.vsz
      stat.utime = sample.utime
      stat.stime = sample.stime
    end

    last_seen_processes.each do |_, stat|
      @processes.delete(stat.pid)
      puts "[PID: #{stat.pid}] exited"
    end
  end

end

module Pluto::Monitor

  Stat   = Struct.new(:pid, :ppid, :pgid, :utime, :stime, :rss, :vsz,
                      :utime_delta, :stime_delta)
  Sample = Struct.new(:pid, :ppid, :pgid, :utime, :stime, :rss, :vsz)

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
        output = %x[ ps -Sax -o pid=,ppid=,pgid=,rss=,vsz=,utime=,stime= ]

        output.split("\n").map do |line|
          pid, ppid, pgid, rss, vsz, utime, stime = *line.split(' ')

          pid  = pid.to_i
          ppid = ppid.to_i
          pgid = pgid.to_i
          rss  = rss.to_i * 1024
          vsz  = vsz.to_i * 1024

          next if Process.pid == ppid

          if utime =~ RE_TIME
            utime  = 0.0
            utime += $4.to_f
            utime += $3.to_i * 60
            utime += $2.to_i * 3600
            utime += $1.to_i * 86400
          end

          if stime =~ RE_TIME
            stime  = 0.0
            stime += $4.to_f
            stime += $3.to_i * 60
            stime += $2.to_i * 3600
            stime += $1.to_i * 86400
          end

          Pluto::Monitor::Sample.new(pid, ppid, pgid, utime, stime, rss, vsz)
        end
      end

    end
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
      @disco = Pluto::Monitor::Disco.new.start
    end

    Rack::Handler::Thin.run routes,
      :Port => Pluto::Monitor.config.endpoint_port
  end

end