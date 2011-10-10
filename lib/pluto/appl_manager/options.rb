module Pluto::ApplManager::Options

  def self.parse!(argv=ARGV)

    @port      = 3000
    @node      = ENV['PLUTO_NODE'] || `hostname`.strip
    @disco     = ENV['PLUTO_DISCO']
    @appl_dir  = Pathname.new('apps').expand_path
    @tmp_dir   = Pathname.new('tmp').expand_path

    OptionParser.new do |opts|
      opts.banner = "Usage: pluto-appl-manager [options]"

      opts.on("-p", "--port PORT", Integer,
              "The port for the HTTP API.") do |p|
        @port = p.to_i
      end

      opts.on("-a", "--appl-dir DIR",
              "Path to the application directory (default: apps).") do |d|
        @appl_dir = Pathname.new(d || 'apps').expand_path
      end

      opts.on("-t", "--tmp-dir DIR",
              "The path to the tmp directory (default: tmp).") do |d|
        @tmp_dir = Pathname.new(d || 'tmp').expand_path
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
    attr_accessor :appl_dir
    attr_accessor :tmp_dir
  end

  def self.endpoint
    "#{node}:#{port}"
  end

  def self.task_dir
    tmp_dir + 'tasks'
  end

  def self.cache_dir
    tmp_dir + 'apps'
  end

end
