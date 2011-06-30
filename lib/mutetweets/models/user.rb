class User
  include DataMapper::Resource
  
  has n, :mutes
  
  property :id, Serial
  property :screen_name, String, :required => true, :unique_index => true
  property :twitter_id, Integer
  property :access_token, String, :length => 64  # tokens can be null if the user sends a mute but hasn't registered yet
  property :secret_token, String, :length => 64
  property :welcome_sent, Boolean, :default => false
  property :created_at, DateTime, :required => true, :index => true
  
  def registered?
    !(access_token.empty? || secret_token.empty?)
  end
  
  def clear_tokens!
    update(:access_token => nil, :secret_token => nil)
  end
end
