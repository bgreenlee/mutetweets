#!/usr/bin/env ruby
ROOT_DIR = File.join(File.dirname(__FILE__), "..")
$:.unshift "#{ROOT_DIR}/lib"
$:.unshift "#{ROOT_DIR}/vendor/twitter_oauth/lib"

require 'logger'
require 'optparse'
require 'mutetweets/logger'
require 'rubygems'
require 'twitter_oauth'
require 'mutetweets/models'
require 'mutetweets/client'
require 'mutetweets/tweet_stream_processor'

include MuteTweets::Logger

# defaults
options = {
  :verbose => false,
  :debug => false
}

OptionParser.new do |opts|
  opts.on("-v", "--verbose", "Be verbose (output to stdout)") { |v| options[:verbose] = true }
  opts.on("-d", "--debug", "Debug logging") { |v| options[:debug] = true }
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

set_log_output($stdout) if options[:verbose]
set_log_level(:debug) if options[:verbose] || options[:debug]
logger.debug "starting daemon"

# read config
config = YAML.load_file(File.join(ROOT_DIR, "config.yml")) rescue nil || {}

# set up the db
DataMapper.setup(:default, config['database'])
DataMapper.auto_upgrade!

# create twitter client
client = MuteTweets::Client.new(config)

begin
  client.sync_followers!
  # process tweets
  MuteTweets::TweetStreamProcessor.new(client).process
rescue JSON::ParserError => e
  msg = ''
  if e.message =~ /trackPageview\('(\d+ Error)'/
    msg << $1
  else
    msg << e.message
  end
  
  logger.warn "twitter barfed: #{msg}; backtrace: #{e.backtrace}"
end
