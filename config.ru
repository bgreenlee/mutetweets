#!/usr/bin/env ruby
root_dir = File.dirname(__FILE__)
$:.unshift *%w{
  lib
  vendor/twitter_oauth/lib
  vendor/sinatra/lib
}.map {|lib| "#{root_dir}/#{lib}"}

require 'sinatra'
require 'rubygems'
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
