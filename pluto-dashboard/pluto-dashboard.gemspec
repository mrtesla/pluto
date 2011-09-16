# -*- encoding: utf-8 -*-
$:.push File.expand_path("../../pluto-core/lib", __FILE__)
require "pluto/version"

Gem::Specification.new do |s|
  s.name        = "pluto-dashboard"
  s.version     = Pluto::VERSION
  s.authors     = ["Simon Menke"]
  s.email       = ["simon.menke@gmail.com"]
  s.homepage    = "http://github.com/fd/pluto"
  s.summary     = %q{[PLUTO] Dashboard}
  s.description = %q{[PLUTO] Dashboard}

  s.rubyforge_project = "pluto"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "yajl-ruby"
  s.add_runtime_dependency "cramp"
  s.add_runtime_dependency "thin"
  s.add_runtime_dependency "http_router"
  s.add_runtime_dependency "pluto-core"
end