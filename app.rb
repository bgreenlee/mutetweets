#!/usr/bin/env ruby
require 'rubygems'
require 'rack/logger'
require 'sinatra'
require 'twitter_oauth'
require 'mutetweets/models'
require 'mutetweets/helpers'

configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
  LOGGER = Logger.new("../logs/sinatra.log")
  
  DataMapper.setup(:default, @@config['database'])
  DataMapper.auto_upgrade!
end

before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  @client = TwitterOAuth::Client.new(
    :consumer_key => @@config['consumer_key'],
    :consumer_secret => @@config['consumer_secret'],
    :token => session[:access_token],
    :secret => session[:secret_token]
  )
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

      if !user.registered?
        user.access_token = @access_token.token
        user.secret_token = @access_token.secret
        user.save
      end
      
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

# for site monitoring
get '/ping' do 
end
