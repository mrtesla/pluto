module Pluto::ApplManager::Options

  def self.parse!(argv=ARGV)

    @node         = ENV['PLUTO_NODE'] || `hostname`.strip
    @disco        = ENV['PLUTO_DISCO']
    @appl_dir     = Pathname.new('apps').expand_path
    @tmp_dir      = Pathname.new('tmp').expand_path
    @blessed_apps = (ENV['PLUTO_BLESSED_APPS'] || '').split(' ')

    OptionParser.new do |opts|
      opts.banner = "Usage: pluto-appl-manager [options]"

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

    @blessed_apps.push('pluto') unless @blessed_apps.include?('pluto')
  end

  class << self
    attr_accessor :node
    attr_accessor :disco
    attr_accessor :appl_dir
    attr_accessor :tmp_dir
    attr_accessor :blessed_apps
  end

  def self.task_dir
    tmp_dir + 'tasks'
  end

  def self.cache_dir
    tmp_dir + 'apps'
  end

end
