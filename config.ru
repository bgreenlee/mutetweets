#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'

root_dir = File.dirname(__FILE__)
$:.unshift File.join(root_dir, "lib")

set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, "lib", "mutetweets", "app.rb")
set :raise_errors, true # disable when we're ready for production
disable :run

log = File.new(File.join(root_dir, "..", "logs", "sinatra.log"), "a+")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
