#!/usr/bin/env ruby
require 'rack/logger'
require 'helpers'
require 'oauth'
require 'twitter'
require 'mutetweets/models'
require 'erubis'
require 'tzinfo'
require 'active_support/all'

configure do
  set :sessions, true
  set :config, YAML.load_file("config.yml") rescue nil || {}
  LOGGER = Logger.new("log/sinatra.log", development? ? ::Logger::DEBUG : ::Logger::INFO)

  DataMapper.setup(:default, settings.config['database'])
  DataMapper.auto_upgrade!
  DataMapper.finalize
end

before do
  # don't bother setting up the session for pings
  next if request.path_info =~ /ping$/

  if session[:user]
    if @user = User.get(session[:user])
      @num_mutes = @user.mutes.active.count
    else
      reset_session
    end
  end

  consumer_key = settings.config['consumer_key']
  consumer_secret = settings.config['consumer_secret']

  @client ||= Twitter::REST::Client.new(
    :consumer_key => consumer_key,
    :consumer_secret => consumer_secret,
    :access_token => session[:access_token],
    :access_token_secret => session[:secret_token])

  @oauth_consumer ||= OAuth::Consumer.new(
    consumer_key,
    consumer_secret,
    :site => 'https://api.twitter.com',
    :request_endpoint => 'https://api.twitter.com',
    :sign_in => true)
end

get '/' do
  erb :home
end

# display the user's active mutes
get '/mutes' do
  redirect '/' unless @user

  @mutes = @user.mutes.active
  erb :mutes
end

# store the request tokens and send to Twitter
get '/connect' do
  begin
    request_token = @oauth_consumer.get_request_token(
      :oauth_callback => settings.config['callback_url'],
      :x_auth_access_type => "write")
  rescue Errno::ECONNRESET => e
    @error = "There was a problem connecting to Twitter. Please try again."
    redirect '/'
  end

  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url.gsub('authorize', 'authenticate')
end

# auth URL is called by twitter after the user has accepted the application
# this is configured on the Twitter application settings page
get '/auth' do
  # Exchange the request token for an access token.

  begin
    request_token = OAuth::RequestToken.new(@oauth_consumer,
                                            session['request_token'],
                                            session['request_secret'])
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    @client.access_token = session[:access_token] = access_token.token
    @client.access_token_secret = session[:secret_token] = access_token.secret
  rescue OAuth::Unauthorized, Errno::ECONNRESET => e
    @error = "There was a problem connecting to Twitter. Please try again."
    redirect '/'
  end

  begin
    # find or create user
    user_info = @client.verify_credentials.attrs
    user = User.first(:twitter_id => user_info[:id_str]) ||
           User.create(:screen_name => user_info[:screen_name],
                       :twitter_id => user_info[:id_str],
                       :access_token => access_token.token,
                       :secret_token => access_token.secret)

    # update user tokens regardless, since they may have disconnected and reconnected
    user.access_token = session[:access_token]
    user.secret_token = session[:secret_token]
    user.save

    session[:user] = user.id
  rescue Twitter::Error::Unauthorized => e
    LOGGER.error(e)
    # fall through to redirect
  end

  redirect '/'
end

get '/disconnect' do
  reset_session
  redirect '/'
end

# for site monitoring
get '/ping' do
end
