class Pluto::ApplManager::ProcfileAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  PROTECTED_ENV_VARS = %w(
    procfile
  )

  def call(env)
    env['PLUTO_PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)

    # process Procfile path
    procfile_path = env['PWD'] + 'Procfile'

    # ignore applications without Procfiles
    unless procfile_path.file?
      logger.warn "Ignoring #{env['PLUTO_APPL_NAME']} (missing Procfile in #{env['PWD']})"
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
      logger.warn "Ignoring #{env['PLUTO_APPL_NAME']} (invalid Procfile in #{env['PWD']})"
      return nil
    end

    # make sure Procfile is not empty
    if procfile.empty?
      logger.warn "Ignoring #{env['PLUTO_APPL_NAME']} (empty Procfile in #{env['PWD']})"
      return nil
    end

    env['PLUTO_PROCFILE'] = procfile

    return env
  end

end