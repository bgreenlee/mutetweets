#!/usr/bin/env ruby
root_dir = File.dirname(__FILE__)
$:.unshift "#{root_dir}/lib"
$:.unshift "#{root_dir}/vendor/twitter_oauth/lib"

require 'rubygems'
require 'sinatra'
require 'app'

set :environment, :production
set :root, root_dir
set :app_file, "#{root_dir}/app.rb"
set :raise_errors, true # disable when we're ready for production
disable :run

log = File.new("#{root_dir}/log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)
set :log_file, log

run Sinatra::Application
