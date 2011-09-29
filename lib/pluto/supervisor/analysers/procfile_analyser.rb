class Pluto::Node::ProcfileAnalyser

  include Pluto::Node::AnalyserHelpers

  PROTECTED_ENV_VARS = %w(
    procfile
  )

  def call(env)
    env['PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)

    # process Procfile path
    procfile_path = env['root'] + 'Procfile'

    # ignore applications without Procfiles
    unless procfile_path.file?
      logger.warn "Ignoring #{env['name']} (missing Procfile in #{env['root']})"
      return nil
    end

    # parse the procfile
    procfile = {}
    procfile_path.read.split("\n").each do |line|
      line = line.split('#', 2).first
      name, command = line.split(':', 2)
      name, command = (name || '').strip, (command || '').strip

      next if name.empty? or command.empty?

      procfile[name] = command
    end

    # verify Procfile
    unless procfile
      logger.warn "Ignoring #{env['name']} (invalid Procfile in #{env['root']})"
      return nil
    end

    # make sure Procfile is not empty
    if procfile.empty?
      logger.warn "Ignoring #{env['name']} (empty Procfile in #{env['root']})"
      return nil
    end

    env['procfile'] = procfile

    return env
  end

end