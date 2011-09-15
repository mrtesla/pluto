require 'rubygems'
require 'bundler/setup'
require 'yajl'
require 'etc'

args = Yajl::Parser.parse($stdin.gets)
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

Dir.chdir(chdir)
File.umask(umask)

if Etc.getpwuid(Process.uid).name == 'root'
  Process.euid = Etc.getpwnam('pluto').uid
  Process.egid = Etc.getpwnam('pluto').gid
end

Process.exec(command)
