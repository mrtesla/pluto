require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern   = "./spec/**/*_spec.rb"
  t.rspec_opts = [
    '-r', File.expand_path("../spec/spec_helper.rb", __FILE__)]
end

task :default => :spec
