#!/usr/bin/env ruby
require 'rack/logger'
require 'helpers'
require 'twitter_oauth'
require 'mutetweets/models'
require 'erubis'

configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
  LOGGER = Logger.new("log/sinatra.log", development? ? ::Logger::DEBUG : ::Logger::INFO)
  
  DataMapper.setup(:default, @@config['database'])
  DataMapper.auto_upgrade!
end

before do
  next if request.path_info =~ /ping$/
  if session[:user]
    @user = User.get(session[:user])
    @num_mutes = @user.mutes.active.count
  end
  
  @client = TwitterOAuth::Client.new(
    :consumer_key => @@config['consumer_key'],
    :consumer_secret => @@config['consumer_secret'],
    :token => session[:access_token],
    :secret => session[:secret_token]
  )
end

get '/' do
  erubis :home
end

# display the user's active mutes
get '/mutes' do
  redirect '/' unless @user
    
  @mutes = @user.mutes.active
  erubis :mutes
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
    # TODO: error handling
  end

  if @client.authorized? && @access_token
      # find or create user
      user_info = @client.info
      user = User.first(:twitter_id => user_info['id']) ||
             User.create(:screen_name => user_info['screen_name'],
                         :twitter_id => user_info['id'],
                         :access_token => @access_token.token,
                         :secret_token => @access_token.secret)

      # update user tokens regardless, since they may have disconnected and reconnected
      user.access_token = session[:access_token] = @access_token.token
      user.secret_token = session[:secret_token] = @access_token.secret
      user.save
      
      session[:user] = user.id
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
