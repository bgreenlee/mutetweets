#!/usr/bin/env ruby
require 'rubygems'
require 'rack/logger'
require 'sinatra'
require 'twitter_oauth'
require 'dm-core'
require 'dm-timestamps'

configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
  LOGGER = Logger.new("../logs/sinatra.log") 
end

#
# database
#
DataMapper.setup(:default, @@config['database'])

class User
  include DataMapper::Resource
  
  has n, :mutes
  
  property :id, Serial
  property :screen_name, String, :nullable => false, :unique_index => true
  property :access_token, String, :nullable => false
  property :secret_token, String, :nullable => false
  property :created_at, DateTime, :nullable => false, :index => true
end

class Mute
  include DataMapper::Resource
  
  belongs_to :user
  
  property :id, Serial
  property :screen_name, String, :nullable => false, :index => true
  property :length, Integer, :nullable => false
  property :created_at, DateTime, :nullable => false, :index => true
end

DataMapper.auto_migrate!

#
# app
#

before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  @client = TwitterOAuth::Client.new(
    :consumer_key => @@config['consumer_key'],
    :consumer_secret => @@config['consumer_secret'],
    :token => session[:access_token],
    :secret => session[:secret_token]
  )
  @rate_limit_status = @client.rate_limit_status
end

get '/' do
  erb :home
end

# store the request tokens and send to Twitter
get '/connect' do
  request_token = @client.request_token(
    :oauth_callback => @@config['callback_url']
  )
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url.gsub('authorize', 'authenticate') 
end

# auth URL is called by twitter after the user has accepted the application
# this is configured on the Twitter application settings page
get '/auth' do
  # Exchange the request token for an access token.
  
  begin
    @access_token = @client.authorize(
      session[:request_token],
      session[:request_token_secret],
      :oauth_verifier => params[:oauth_verifier]
    )
  rescue OAuth::Unauthorized
  end
  
  if @client.authorized?
      # find or create user
      user = User.first(:screen_name => @client.info['screen_name']) || 
             User.create(:screen_name => @client.info['screen_name'], 
                         :access_token => @access_token.token,
                         :secret_token => @access_token.secret)
                    
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user] = @client.info['screen_name']
  end
  
  redirect '/'
end

get '/disconnect' do
  session[:user] = nil
  session[:request_token] = nil
  session[:request_token_secret] = nil
  session[:access_token] = nil
  session[:secret_token] = nil
  redirect '/'
end

# useful for site monitoring
get '/ping' do 
  'pong'
end

helpers do
  def logger
    LOGGER
  end
  
  def partial(name, options={})
    erb("_#{name.to_s}".to_sym, options.merge(:layout => false))
  end
end
