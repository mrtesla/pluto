class Pluto::Node::RvmAnalyser

  include Pluto::Node::AnalyserHelpers

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
    rvm_path RUBY_VERSION GEM_HOME GEM_PATH MY_RUBY_HOME
    IRBRC rvm_ruby_string
  )

  def call(env)
    env['PROTECTED_ENV_VARS'].concat(PROTECTED_ENV_VARS)
    process_rvmrc(env)
    apply_rvm_env(env)
    return env
  end

  def process_rvmrc(env)
    # process .rvmrc path
    rvmrc_path = env['root'] + '.rvmrc'

    unless rvmrc_path.file?
      # no requested ruby
      return
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
      logger.warn "Skipping RMV for #{env['name']} (Invalid .rvmrc in #{env['root']})"
      return
    end

    patches = RVM_PATCHES["#{impl}-#{vers}"]
    if patches
      patch ||= patches.first

      unless patches.include?(patch)
        logger.warn "Skipping RMV for #{env['name']} (Invalid .rvmrc in #{env['root']})"
        return
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

end