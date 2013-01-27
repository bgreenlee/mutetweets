#!/usr/bin/env ruby
ROOT_DIR = File.join(File.dirname(__FILE__), "..")
$:.unshift "#{ROOT_DIR}/lib"

require 'active_support'
require 'logger'
require 'optparse'
require 'rubygems'
require 'json'
require 'twitter'
require 'mutetweets'

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
DataMapper.finalize

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
  logger.warn "twitter barfed: #{msg}"
rescue Twitter::Error::ServiceUnavailable, Twitter::Error::BadGateway => e
  logger.warn "twitter barfed: #{e.message}"
rescue Timeout::Error, Errno::ECONNRESET, Errno::ETIMEDOUT => e
  logger.warn "couldn't connect to twitter: #{e.message}"
end
