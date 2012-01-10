# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pluto/core/version"

Gem::Specification.new do |s|
  s.name        = "pluto"
  s.version     = Pluto::VERSION
  s.authors     = ["Simon Menke"]
  s.email       = ["simon.menke@gmail.com"]
  s.homepage    = "http://github.com/fd/pluto"
  s.summary     = %q{[PLUTO] Easy service managment}
  s.description = %q{[PLUTO] Easy service managment}

  s.rubyforge_project = "pluto"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  # s.add_runtime_dependency 'cramp'
  # s.add_runtime_dependency 'thin'
  # s.add_runtime_dependency 'http_router'

  # s.add_runtime_dependency 'lumberjack_syslog_device'

  s.add_runtime_dependency 'em-http-request'
  s.add_runtime_dependency 'rack', '= 1.3.3'
  s.add_runtime_dependency 'thin'
  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'sinatra-contrib'
  s.add_runtime_dependency 'lumberjack'
  s.add_runtime_dependency 'eventmachine'
  s.add_runtime_dependency 'state_machine'
  s.add_runtime_dependency 'yajl-ruby'
  s.add_runtime_dependency 'thor'
  s.add_runtime_dependency 'statsd-ruby'

end
