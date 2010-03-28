# Sinatra helpers
helpers do
  def logger
    LOGGER
  end
  
  def pluralize(count, word)
    "%d #{count > 1 ? word + 's' : word}" % count
  end
  
  def development?
    ENV['RACK_ENV'] == 'development'
  end
  
  def reset_session
    session[:user] = nil
    session[:request_token] = nil
    session[:request_token_secret] = nil
    session[:access_token] = nil
    session[:secret_token] = nil
  end
end