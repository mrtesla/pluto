class Pluto::TaskManager::API
  def self.run
    PortSubscriber.run
  end

  module PortSubscriber
    @@ports = Set.new

    def self.run
      EM.add_periodic_timer(5 * 60) do # every five minutes
        register_backends_with_alice
      end
    end

    def self.set(port)
      @@ports << port
      register_backends_with_alice([port])
    end

    def self.rmv(port)
      @@ports.delete(port)
    end

    def self.register_backends_with_alice(backends=@@ports)
      return unless ENV['ALICE_ENDPOINT']

      machine = ENV['PLUTO_NODE']
      alice   = ENV['ALICE_ENDPOINT']

      backends = backends.map do |(application, process, serv, port, instance)|
        next unless serv == 'http'
        {
          type:        'backend',
          machine:     machine,
          application: application,
          process:     process,
          instance:    instance.to_i,
          port:        port.to_i
        }
      end

      payload = Yajl::Encoder.encode(backends)
      headers = {
        'Content-Type'   => 'application/json',
        'Content-Length' => payload.size.to_s,
        'Accepts'        => 'application/json'
      }

      req = EventMachine::HttpRequest.new("http://#{alice}/api_v1/register.json").post(
        :head      => headers,
        :keepalive => false,
        :redirects => 3,
        :body      => payload)
    end
  end
end
