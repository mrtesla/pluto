module Pluto::Varnish::Options

  def self.parse!(argv=ARGV)

    @port     = 3000
    @node     = ENV['PLUTO_NODE'] || `hostname`.strip
    @disco    = ENV['PLUTO_DISCO']

    OptionParser.new do |opts|
      opts.banner = "Usage: pluto-varnish [options]"

      opts.on("-p", "--port PORT", Integer,
              "The port for the HTTP API.") do |p|
        @port = p.to_i
      end

      opts.on("-n", "--node HOSTNAME",
              "The hostname for this HTTP API.") do |n|
        @node = n
      end

      opts.on("-d", "--disco ENDPOINT",
              "The HOST:PORT for the disco endpoint.") do |d|
        @disco = d
      end

    end.parse!(argv)

  end

  class << self
    attr_accessor :port
    attr_accessor :node
    attr_accessor :disco
  end

  def self.endpoint
    "#{node}:#{port}"
  end

end
