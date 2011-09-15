require 'rubygems'
require 'bundler/setup'
require 'yajl'
require 'etc'

args = Yajl::Parser.parse(ARGV[0])
env, command, pgroup, unsetenv_others, chdir, umask, close_others = *args

if unsetenv_others
  ENV.each do |key, _|
    ENV.delete(key)
  end
end

env.each do |key, value|
  ENV[key] = value
end

if pgroup
  Process.setpgrp
end

if chdir
  Dir.chdir(chdir)
end

if umask
  File.umask(umask)
end

if Etc.getpwuid(Process.uid).name == 'root' and env['USER'] == 'pluto'
  Process.gid = Etc.getpwnam('pluto').gid
  Process.egid = Etc.getpwnam('pluto').gid
  Process.uid = Etc.getpwnam('pluto').uid
  Process.euid = Etc.getpwnam('pluto').uid
end

Process.exec("/usr/bin/env #{command}")
