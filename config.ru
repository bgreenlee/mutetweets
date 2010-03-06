#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'mutetweets'

root_dir = File.dirname(__FILE__)

set :environment, ENV['RACK_ENV'].to_sym
set :root,        root_dir
set :app_file,    File.join(root_dir, 'mutetweets.rb')
disable :run

run Sinatra::Application

