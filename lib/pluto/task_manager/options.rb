module Pluto::TaskManager::Options

  def self.parse!(argv=ARGV)

    @node    = ENV['PLUTO_NODE'] || `hostname`.strip
    @tmp_dir = Pathname.new('tmp').expand_path

    OptionParser.new do |opts|
      opts.banner = "Usage: pluto-task-manager [options]"

      opts.on("-n", "--node HOSTNAME",
              "The hostname for this HTTP API.") do |n|
        @node = n
      end

      opts.on("-t", "--tmp-dir DIR",
              "The path to the tmp directory (default: tmp).") do |d|
        @tmp_dir = Pathname.new(d || 'tmp').expand_path
      end

    end.parse!(argv)

  end

  class << self
    attr_accessor :node
    attr_accessor :tmp_dir
  end

  def self.data_dir
    @tmp_dir + 'tasks'
  end

  def self.lock_file
    @tmp_dir + 'task-manager.lock'
  end

end
