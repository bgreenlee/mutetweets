# table representing muting actions
class Mute
  include DataMapper::Resource
  
  belongs_to :user
  
  property :id, Serial
  property :screen_name, String, :required => true, :index => true  # user being muted
  property :expires_at, DateTime, :required => true  # when the mute expires
  property :created_at, DateTime, :required => true, :index => true
  property :unfollowed, Boolean, :default => false  # set to true once we have successfully unfollowed
  property :refollowed, Boolean, :default => false  # set to true once we have successfully refollowed
  property :retries, Integer, :default => 0  # retry counter in the case of errors unfollowing or refollowing
end
