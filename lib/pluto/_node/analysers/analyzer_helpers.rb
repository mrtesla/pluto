module Pluto::Node::AnalyserHelpers

  def env_expand(val, env)
    val.gsub(/[$]([a-zA-Z][a-zA-Z0-9_]*)/) do
      var = $1
      if /^PORT_([a-zA-Z][a-zA-Z0-9_]*)$/ =~ var
        "$#{var}"
      else
        env[var] || ''
      end
    end
  end

  def env_export(env, var, val, protect=true)
    if protect and PROTECTED_ENV_VARS.include?(var)
      logger.warn("Not exporting protected ENV ($#{var}) (for .envrc in #{env['root']})")
      return
    end

    expand = true

    if val[0..0] == '"' and val[-1..-1] == '"'
      val = Yajl::Parser.parse(val)
    elsif val[0..0] == "'" and val[-1..-1] == "'"
      val = Yajl::Parser.parse('"'+val[1..-2]+'"')
      expand = false
    end

    if expand
      val = env_expand(val, env)
    end

    env[var] = val
  end

  def env_unset(env, var)
    if PROTECTED_ENV_VARS.include?(var)
      logger.warn("Not unsetting protected ENV ($#{var}) (for .envrc in #{env['root']})")
      return
    end

    env.delete(var)
  end

  def logger
    Pluto.logger
  end

end