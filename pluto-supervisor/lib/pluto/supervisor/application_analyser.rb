class Pluto::Supervisor::ApplicationAnalyser
  
  if Etc.getpwuid(Process.uid).name == 'root'
    RVM_PATH = Pathname.new('/usr/local/rvm')
  else
    RVM_PATH = Pathname.new(File.expand_path('~/.rvm'))
  end
  
  RVM_RUNTIMES = %w( ruby rbx ree )
  RVM_VERSIONS = {
    'ruby' => ['1.8.7', '1.9.2'],
    'ree'  => ['1.8.7'],
    'rbx'  => ['1.2.4']
  }
  RVM_PATCHES = {
    'ruby-1.8.7' => ['p352'],
    'ruby-1.9.2' => ['p290', 'p180'],
    'ree-1.8.7'  => ['2011.03']
  }
  PROTECTED_ENV_VARS = %w(
    name root procfile concurrency
    
    PATH PWD HOME USER rvm_path RUBY_VERSION GEM_HOME GEM_PATH MY_RUBY_HOME
    IRBRC rvm_ruby_string
  )

  
  def initialize(root=nil)
    root ||= (Pluto.root + 'apps')
    @root = Pathname.new(root.to_s)
  end
  
  def run
    process_application_directories
    process_application_procs
    return @processes
  end
  
private
  
  def logger
    Pluto.logger
  end
  
  def process_application_directories
    @applications = {}
    
    process_buildin_applications
    
    return unless Pluto::Supervisor::Dashboard.shared.booted?
    
    @root.children.each do |child|
      
      env = {}
      
      process_default_env(env)
      
      process_name(env, child)
      next unless env['name']
      
      process_root(env, child)
      next unless env['root']
      
      process_procfile(env)
      next unless env['procfile']
      
      process_concurrencyrc(env)
      process_dashboard_concurrency(env)
      
      process_uidgid(env)
      process_rvmrc(env)
      apply_rvm_env(env)
      process_envrc(env)
      process_dashboard_env(env)
      
      @applications[env['name']] = env
      
    end
  end
  
  def process_application_procs
    @processes = []
    @applications.each do |_, env|
      env['procfile'].each do |name, _|
        (env['concurrency'][name] || 1).times do |i|
          
          proc_env = {}.merge(env)
          proc_env['SUP_PROC'] = name
          proc_env['SUP_INSTANCE'] = (i + 1)
          process_proc_env(proc_env)
          
          pid_file = Pluto.root + 'pids' + (proc_env['SUP_PID'] + '.pid')
          proc_env['SUP_PID_FILE'] = pid_file.to_s
          
          @processes << proc_env
          
        end
      end
    end
  end

  def process_buildin_applications
    services = Pluto::Supervisor.config.services
    
    if services.include?('pluto-disco')
      env = {
        'name'     => 'pluto-disco',
        'root'     => Pluto.root,
        'procfile' => {
          'endpoint' => 'bundle exec pluto disco'
        },
        'concurrency' => {},
        'RUBY_VERSION' => ENV['RUBY_VERSION'],
        'SUP_BUILT_IN' => true
      }
      
      process_default_env(env)
      apply_rvm_env(env)
      
      @applications['pluto-disco'] = env
    end
    
    if services.include?('pluto-dashboard')
      env = {
        'name'     => 'pluto-dashboard',
        'root'     => Pluto.root,
        'procfile' => {
          'endpoint' => 'bundle exec pluto dashboard'
        },
        'concurrency' => {},
        'RUBY_VERSION' => ENV['RUBY_VERSION'],
        'SUP_BUILT_IN' => true
      }
      
      process_default_env(env)
      apply_rvm_env(env)
      
      @applications['pluto-dashboard'] = env
    end
    
    if services.include?('pluto-varnish')
      env = {
        'name'     => 'pluto-varnish',
        'root'     => Pluto.root,
        'procfile' => {
          'endpoint' => 'bundle exec pluto varnish'
        },
        'concurrency' => {},
        'RUBY_VERSION' => ENV['RUBY_VERSION'],
        'SUP_BUILT_IN' => true
      }
      
      process_default_env(env)
      apply_rvm_env(env)
      
      @applications['pluto-varnish'] = env
    end
    
    if services.include?('pluto-monitor')
      env = {
        'name'     => 'pluto-monitor',
        'root'     => Pluto.root,
        'procfile' => {
          'endpoint' => 'bundle exec pluto monitor'
        },
        'concurrency' => {},
        'RUBY_VERSION' => ENV['RUBY_VERSION'],
        'SUP_BUILT_IN' => true
      }
      
      process_default_env(env)
      apply_rvm_env(env)
      
      @applications['pluto-monitor'] = env
    end
  end

  def process_default_env(env)
    env['PATH'] = '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin'
  end

  def process_name(env, path)
    # get the application name
    name = path.basename.to_s
    
    # ignore files staring with a '.'
    return if name[0,1] == '.'
    
    env['name'] = name
  end

  def process_root(env, path)
    # ignore non-symlinks and non-directories
    unless path.symlink? or path.directory?
      logger.warn "Ignoring #{env['name']} (#{path} is not a directory or a symlink)"
      return
    end
    
    # resolve symlinks
    while path.symlink?
      path = path.dirname + path.readlink
    end
    
    # ignore non-directories
    unless path.directory?
      logger.warn "Ignoring #{env['name']} (#{path} is not a directory)"
      return
    end
    
    env['root'] = path
  end

  def process_procfile(env)
    # process Procfile path
    procfile_path = env['root'] + 'Procfile'
    
    # ignore applications without Procfiles
    unless procfile_path.file?
      logger.warn "Ignoring #{env['name']} (missing Procfile in #{env['root']})"
      return
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
      return
    end
    
    # make sure Procfile is not empty
    if procfile.empty?
      logger.warn "Ignoring #{env['name']} (empty Procfile in #{env['root']})"
      return
    end
    
    env['procfile'] = procfile
  end
  
  def process_concurrencyrc(env)
    env['concurrency'] = {}
  end
  
  def process_dashboard_concurrency(env)
    dashboard = Pluto::Supervisor::Dashboard.shared
    conf      = dashboard[env['name']]
    
    return unless conf and conf['concurrency']
    
    env['concurrency'].merge!(conf['concurrency'] || {})
  end
  
  def process_uidgid(env)
    env['USER'] = 'pluto'
  end
  
  def process_rvmrc(env)
    # process .rvmrc path
    rvmrc_path = env['root'] + '.rvmrc'
    
    # use default ruby for applications without .rvmrc
    unless rvmrc_path.file?
      logger.warn "Using default ruby (1.8.7) for #{env['name']} (missing .rvmrc in #{env['root']})"
      ruby_version = 'ruby-1.8.7'
    end
    
    # parse .rvmrc file
    rvmrc_path.read.split("\n").each do |line|
      line = line.split('#', 2).first.strip
      next unless /^rvm\s+(.+)$/ =~ line
      line = $1
      if /^use\s+(.+)$/ =~ line then line = $1 end
      line = line.split('@', 2).first
      next unless /^[a-z0-9_.-]+$/ =~ line
      ruby_version = line
    end
    
    # normalize ruby version
    ruby_version = ruby_version.split('-')[0,3]
    if !RVM_RUNTIMES.include?(ruby_version[0])
      ruby_version.unshift('ruby')
    end
    impl, vers, patch = *ruby_version
    
    unless RVM_RUNTIMES.include?(impl)
      logger.warn "Using default ruby (1.8.7) for #{env['name']} (Invalid .rvmrc in #{env['root']})"
      impl = 'ruby'
    end
    
    vers ||= RVM_VERSIONS[impl].first
    
    unless RVM_VERSIONS[impl].include?(vers)
      logger.warn "Using default ruby (1.8.7) for #{env['name']} (Invalid .rvmrc in #{env['root']})"
      vers = '1.8.7'
    end
    
    patches = RVM_PATCHES["#{impl}-#{vers}"]
    if patches
      patch ||= patches.first
      
      unless patches.include?(patch)
        logger.warn "Using default ruby (1.8.7) for #{env['name']} (Invalid .rvmrc in #{env['root']})"
        patch = RVM_PATCHES["ruby-1.8.7"].first
      end
    end
    
    ruby_version = [impl, vers, patch].compact.join('-')
    env['RUBY_VERSION'] = ruby_version
    
  end
  
  def apply_rvm_env(env)
    ruby_version = env['RUBY_VERSION']
    
    unless (RVM_PATH + 'rubies' + ruby_version + 'bin').directory?
      logger.warn "Ruby not found (#{ruby_version}) for #{env['name']} (Invalid .rvmrc in #{env['root']})"
      return
    end
    
    env['PATH']            = [
      (RVM_PATH + 'gems' + ruby_version + 'bin'),
      (RVM_PATH + 'gems' + (ruby_version + '@global') + 'bin'),
      (RVM_PATH + 'rubies' + ruby_version + 'bin'),
      (RVM_PATH + 'bin'),
      env['PATH']
    ].flatten.compact.join(':')
    env['rvm_path']        = RVM_PATH
    env['GEM_HOME']        = RVM_PATH + 'gems' + ruby_version
    env['GEM_PATH']        = [
      (RVM_PATH + 'gems' + ruby_version),
      (RVM_PATH + 'gems' + (ruby_version + '@global'))
    ].join(':')
    env['MY_RUBY_HOME']    = RVM_PATH + 'rubies' + ruby_version
    env['IRBRC']           = RVM_PATH + 'rubies' + ruby_version + '.irbrc'
    env['rvm_ruby_string'] = ruby_version
    
  end
  
  def process_envrc(env)
    # process .envrc path
    envrc_path = env['root'] + '.envrc'
    
    unless envrc_path.file?
      logger.warn "Skipping .envrc for #{env['name']} (Missing .envrc in #{env['root']})"
      return
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
  end
  
  def process_dashboard_env(env)
    dashboard = Pluto::Supervisor::Dashboard.shared
    conf      = dashboard[env['name']]
    
    return unless conf and conf['environment']
    
    conf['environment'].each do |key, val|
      env_export(env, key.to_s, val.to_s)
    end
  end
  
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
  
  def process_proc_env(env)
    name     = env.delete('name')
    root     = env.delete('root')
    procfile = env.delete('procfile')
    env.delete('concurrency')
    
    env['SUP_APPLICATION'] = name
    env['PWD']             = root
    env['SUP_COMMAND']     = env_expand(procfile[env['SUP_PROC']], env)
    
    env.each do |key, value|
      env[key] = value.to_s
    end
    
    digest = Digest::SHA1.new
    env.keys.sort.each do |key|
      digest << key
      digest << env[key]
    end
    env['SUP_PID'] = digest.hexdigest
    
  end
  
end
