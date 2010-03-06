#!/usr/bin/env ruby
require 'mutetweets'

Sinatra::Application.default_options.merge!(
  :run => false,
  :env => ENV['RACK_ENV']
)

run Sinatra::Application

