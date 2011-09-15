require 'rubygems'
require 'bundler/setup'
require 'yajl'

args = Yajl::Parser.parse($stdin.gets)
Process.exec(*args)
