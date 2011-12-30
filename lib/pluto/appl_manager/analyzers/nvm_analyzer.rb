class Pluto::ApplManager::NvmAnalyzer

  include Pluto::ApplManager::AnalyzerHelpers

  NVM_PATH = begin
    [
      Pathname.new('/usr/local/nvm'),
      Pathname.new('~/.nvm').expand_path
    ].detect(&:directory?)
  end

  NVM_VERSIONS = ['v0.2.6', 'v0.4.9', 'v0.4.12', 'v0.6.6']

  PROTECTED_ENV_VARS = %w(
    NODE_VERSION
  )

  def call(env)
    env['PLUTO_PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)
    
    return env unless NVM_PATH
    
    process_nvmrc(env)
    apply_nvm_env(env)
    
    return env
  end

  def process_nvmrc(env)
    # process .nvmrc path
    nvmrc_path = env['PWD'] + '.nvmrc'
    node_version = nil

    unless nvmrc_path.file?
      # no requested ruby
      return
    end

    # parse .nvmrc file
    nvmrc_path.read.split("\n").each do |line|
      line = line.split('#', 2).first.strip
      next unless /^nvm\s+(.+)$/ =~ line
      line = $1
      if /^use\s+(.+)$/ =~ line then line = $1 end
      next unless /^v?([a-z0-9_.-]+)$/ =~ line
      node_version = "v#{$1}"
    end

    unless NVM_VERSIONS.include?(node_version)
      logger.warn "Skipping NMV for #{env['PLUTO_APPL_NAME']} (Invalid .nvmrc in #{env['PWD']})"
      return
    end

    env['NODE_VERSION'] = node_version
  end

  def apply_nvm_env(env)
    node_version = env['NODE_VERSION']

    unless node_version
      return
    end

    unless (NVM_PATH + node_version + 'bin').directory?
      logger.warn "Node not found (#{node_version}) for #{env['PLUTO_APPL_NAME']} (Invalid .nvmrc in #{env['root']})"
      return
    end

    env['PATH'] = [
      (NVM_PATH + node_version + 'bin'),
      env['PATH']
    ].flatten.compact.join(':')
  end

end