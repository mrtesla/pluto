class Pluto::Node::CLI < Thor

  class_option :root, :aliases => "-R",
    :type => :string, :default => '.',
    :desc => "Path to the root of a pluto installation"

  desc "start", "Start the Pluto task manager."
  def start
    require 'digest/sha1'
    require 'pathname'

    root = Pathname.new(options[:root]).expand_path

    procfile = root + 'Procfile'

    unless procfile.file?
      say_status('ERROR', "No Procfile found in #{root}", :red)
      exit 1
    end

    uuid = Digest::SHA1.hexdigest([
      'pluto',
      root.to_s,
      procfile.stat.mtime.to_s
    ].join("\0"))

    # build the default env
    env = {
      'PWD'             => root,
      'PLUTO_APPL_NAME' => 'pluto',
      'PLUTO_APPL_UUID' => uuid
    }

    # analyze the app
    env = Pluto::ApplManager::ApplAnalyzer.new.call(env)
    unless env
      say_status('ERROR', "Invalid node #{root}", :red)
      exit 1
    end

    # analyze the procs
    procs = Pluto::ApplManager::ProcAnalyzer.new.call(env)

    cache = Pluto::ApplManager::Options.parse!([])
    cache = Pluto::ApplManager::ApplCache.new
    cache.store(env, procs)

    task_manager = procs.detect do |env|
      env['PLUTO_PROC_NAME'] == 'task-manager'
    end

    Pluto::TaskManager::Options.parse!([])
    Pluto::TaskManager::Task.supervisor = task_manager
    Pluto::TaskManager::Task.boot_supervisor
    
    say_status('INFO', "Node is booting")
  end

  desc "stop", "Stop the Pluto task manager."
  def stop
    require 'yajl'

    root = Pathname.new(options[:root]).expand_path
    lock = root + "tmp/task-manager.lock"

    unless lock.file?
      say_status('INFO', "Node is already down")
      return
    end

    uuid = lock.read.strip
    if uuid.empty?
      say_status('INFO', "Node is already down")
      return
    end

    proc = root + "tmp/tasks/#{uuid}.proc"
    unless proc.file?
      say_status('INFO', "Node is already down")
      return
    end

    info = Yajl::Parser.parse(proc.read)
    Process.kill('QUIT', info['pid'].to_i) rescue nil
    
    if Pluto::TaskManager::Task.locked_file?(lock)
      lock.open('r') do |f|
        f.flock(File::LOCK_EX)
      end
    end
    
    say_status('INFO', "Node is down")
  end

  desc "restart", "Restart the Pluto task manager."
  def restart
    stop
    start
  end

end
