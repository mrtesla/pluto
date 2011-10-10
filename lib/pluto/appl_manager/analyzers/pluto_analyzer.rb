class Pluto::ApplManager::PlutoAnalyzer

  def call(env)
    if env['PLUTO_APPL_NAME'] == 'pluto'
      env['PLUTO_CONCURRENCY']['task-manager'] = 2
    end

    return env
  end

end