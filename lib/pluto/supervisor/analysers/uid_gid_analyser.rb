class Pluto::Node::UidGidAnalyser

  PROTECTED_ENV_VARS = %w(
    USER
  )

  def call(env)
    env['PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)
    env['USER'] = 'pluto'
    return env
  end

end