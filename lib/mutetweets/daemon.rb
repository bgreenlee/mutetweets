#!/usr/bin/env ruby
ROOT_DIR = File.join(File.dirname(__FILE__), "..", "..")
$:.unshift File.join(ROOT_DIR, "lib")

require 'rubygems'
require 'twitter_oauth'
require 'mutetweets/models'

# read config
config = YAML.load_file(File.join(ROOT_DIR, "config.yml")) rescue nil || {}

# set up the db
DataMapper.setup(:default, config['database'])

# create twitter client
client = TwitterOAuth::Client.new(
  :consumer_key => config['consumer_key'],
  :consumer_secret => config['consumer_secret'],
  :token => config['client_access_token'],
  :secret => config['client_secret_token']
)

# get mentions
mention_stream = MentionStream.first || MentionStream.new
options = {"count" => 200}
options["since_id"] = mention_stream.last_id if mention_stream.last_id > 0
mentions = client.mentions(options).map {|m| Mention.new(m) }
mutes = mentions.select {|m| m.valid_mute? }

mutes.each do |mute|
  user = User.first(:screen_name => mute.muter) || User.create(:screen_name => mute.muter)
  Mute.create(:user => user, :screen_name => mute.mutee, :expires_at => Time.now + mute.length)
  # if the user doesn't have tokens, send a message with a login link
  unless user.registered?
    client.update("@#{user.screen_name} Welcome to Mute Tweets! Go to http://mutetweets.com to get started.")
  end
end

# update last_id
if mentions.any?
  mention_stream.last_id = mentions.last.id
  mention_stream.save
end
