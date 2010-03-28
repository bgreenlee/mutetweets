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
end