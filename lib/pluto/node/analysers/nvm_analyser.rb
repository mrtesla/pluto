module Pluto::Node::NvmAnalyser
  
  if Etc.getpwuid(Process.uid).name == 'root'
    NVM_PATH = Pathname.new('/usr/local/nvm')
  else
    NVM_PATH = Pathname.new(File.expand_path('~/.nvm'))
  end
  
  NVM_VERSIONS = ['v0.2.6', 'v0.4.9', 'v0.4.12']
  
  PROTECTED_ENV_VARS = %w(
    NODE_VERSION
  )
  
  def self.included(base)
    base.const_get('PROTECTED_ENV_VARS').concat(PROTECTED_ENV_VARS)
  end
  
protected

  def process_application(env)
    super(env)
    
    process_nvmrc(env)
    apply_nvm_env(env)
  end
  
  def process_nvmrc(env)
    # process .nvmrc path
    nvmrc_path = env['root'] + '.nvmrc'
    
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
      logger.warn "Skipping NMV for #{env['name']} (Invalid .nvmrc in #{env['root']})"
      return
    end
    
    env['NODE_VERSION'] = node_version
  end
  
  def apply_nvm_env(env)
    node_version = env['NODE_VERSION']
    
    unless (NVM_PATH + node_version + 'bin').directory?
      logger.warn "Node not found (#{node_version}) for #{env['name']} (Invalid .nvmrc in #{env['root']})"
      return
    end
    
    env['PATH'] = [
      (NVM_PATH + node_version + 'bin'),
      env['PATH']
    ].flatten.compact.join(':')
  end
  
end