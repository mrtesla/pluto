module Pluto::ApplManager::AnalyzerHelpers

  def env_expand(val, env)
    val.gsub(/[$]([a-zA-Z][a-zA-Z0-9_]*)/) do
      var = $1
      if /^PORT(?:_(?:[a-zA-Z][a-zA-Z0-9_]*))?$/ =~ var
        "$#{var}"
      else
        (env[var] || '').to_s
      end
    end
  end

  def env_export(env, var, val, protect=true)
    protected_env_vars = env['PLUTO_PROTECTED_ENV_VARS']
    
    if protect and protected_env_vars.include?(var)
      logger.warn("Not exporting protected ENV ($#{var}) (for .envrc in #{env['PWD']})")
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
    protected_env_vars = env['PLUTO_PROTECTED_ENV_VARS']
    
    if protected_env_vars.include?(var)
      logger.warn("Not unsetting protected ENV ($#{var}) (for .envrc in #{env['PWD']})")
      return
    end

    env.delete(var)
  end

  def logger
    Pluto.logger
  end

end