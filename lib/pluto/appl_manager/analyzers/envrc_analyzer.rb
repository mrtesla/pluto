class Pluto::ApplManager::EnvrcAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  def call(env)

    # process .envrc path
    envrc_path = env['PWD'] + '.envrc'

    unless envrc_path.file?
      # no .envrc requested
      return env
    end

    envrc_path.read.split("\n").each do |line|
      line = line.split('#', 2).first.strip
      case line
      when /^export\s+([a-zA-Z0-9_]+)[=](.+)$/
        env_export(env, $1, $2)

      when /^unset\s+([a-zA-Z0-9_]+)$/
        env_unset(env, $1)

      end
    end

    return env
  end

end