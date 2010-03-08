#!/usr/bin/env ruby
ROOT_DIR = File.join(File.dirname(__FILE__), "..", "..")
$:.unshift "#{ROOT_DIR}/lib"
$:.unshift "#{ROOT_DIR}/vendor/twitter_oauth/lib"

require 'rubygems'
require 'twitter_oauth'
require 'mutetweets/models'

# read config
config = YAML.load_file(File.join(ROOT_DIR, "config.yml")) rescue nil || {}

# set up the db
DataMapper.setup(:default, config['database'])
DataMapper.auto_upgrade!

# create twitter client
client = TwitterOAuth::Client.new(
  :consumer_key => config['consumer_key'],
  :consumer_secret => config['consumer_secret'],
  :token => config['client_access_token'],
  :secret => config['client_secret_token']
)

# process followers
# we need to sync our followers and friends--friending people who are following us and unfriending people who are no longer following us
followers = client.followers_ids
friends = client.friends_ids
to_friend = followers - friends
to_unfriend = friends - followers

to_unfriend.each {|id| client.unfriend(id) }
to_friend.each {|id| client.friend(id) }

# process tweets
TweetStream.process!(client)

# process mutes
