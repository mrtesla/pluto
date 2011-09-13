# -*- encoding: utf-8 -*-
$:.push File.expand_path("../../pluto-core/lib", __FILE__)
require "pluto/version"

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

  s.add_runtime_dependency "pluto-supervisor"
  s.add_runtime_dependency "pluto-disco"
end
