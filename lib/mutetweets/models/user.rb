class User
  include DataMapper::Resource
  
  has n, :mutes
  
  property :id, Serial
  property :screen_name, String, :required => true, :unique_index => true
  property :access_token, String, :length => 64  # tokens can be null if the user sends a mute but hasn't registered yet
  property :secret_token, String, :length => 64
  property :created_at, DateTime, :required => true, :index => true
  
  def registered?
    !(access_token.blank? || secret_token.blank?)
  end
end
