module Pluto::Varnish::Options

  def self.parse!(argv=ARGV)

    @port       = 3000
    @node       = ENV['PLUTO_NODE'] || `hostname`.strip
    @disco      = ENV['PLUTO_DISCO']
    @fallback   = ENV['PLUTO_FALLBACK']
    @vcl_file   = Pathname.new(ENV['PLUTO_VCL_FILE'] || '/etc/varnish/default.vcl').expand_path
    @vcl_reload = ENV['PLUTO_VCL_RELOAD'] || '/etc/init.d/varnish reload'

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

      opts.on("--fallback HOST:PORT",
              "The fallback backend for varnish.") do |n|
        @fallback = n
      end

      opts.on("--vcl-file PATH",
              "The path to the varnish config file.") do |d|
        @vcl_file = Pathname.new(d).expand_path
      end

      opts.on("--vcl-reload COMMAND",
              "The command to reload the varnish config file.") do |d|
        @vcl_reload = d
      end

    end.parse!(argv)

  end

  class << self
    attr_accessor :port
    attr_accessor :node
    attr_accessor :disco
    attr_accessor :fallback
    attr_accessor :vcl_file
    attr_accessor :vcl_reload
  end

  def self.endpoint
    "#{node}:#{port}"
  end

end
