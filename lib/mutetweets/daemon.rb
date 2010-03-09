#!/usr/bin/env ruby
ROOT_DIR = File.join(File.dirname(__FILE__), "..", "..")
$:.unshift "#{ROOT_DIR}/lib"
$:.unshift "#{ROOT_DIR}/vendor/twitter_oauth/lib"

require 'rubygems'
require 'twitter_oauth'
require 'mutetweets/models'
require 'mutetweets/client'
require 'optparse'

# defaults
options = {
  :verbose => false
}

OptionParser.new do |opts|
  opts.on("-v", "--verbose", "Be verbose") { |v| options[:verbose] = true }
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# read config
config = YAML.load_file(File.join(ROOT_DIR, "config.yml")) rescue nil || {}

# set up the db
DataMapper.setup(:default, config['database'])
DataMapper.auto_upgrade!

# create twitter client
client = MuteTweets::Client.new(config)

client.sync_followers!

# process tweets
TweetStreamProcessor.new(client, options[:verbose]).process
