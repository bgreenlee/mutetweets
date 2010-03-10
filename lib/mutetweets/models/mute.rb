# table representing muting actions
class Mute
  include DataMapper::Resource
  
  class Status
    NEW = 0
    ACTIVE = 1
    EXPIRED = 2
    ERROR = 3
  end
    
  belongs_to :user
  
  property :id, Serial
  property :screen_name, String, :required => true, :index => true  # user being muted
  property :expires_at, DateTime, :required => true  # when the mute expires
  property :created_at, DateTime, :required => true, :index => true
  property :direct_message, Boolean, :default => false # true if the mute was created via a DM
  property :verbose, Boolean, :default => false # true if user wants to be messaged on un/refollow
  property :status, Integer, :default => 0
  property :retries, Integer, :default => 0  # retry counter in the case of errors unfollowing or refollowing
  property :error, Text
  
  def expired?
    expires_at < Time.now
  end
  
  # return true if there's an active mute for this user and mutee
  def self.active_mute?(user, mutee)
    !!first(:user => user, :screen_name => mutee, :expires_at.gt => Time.now, :status => [Status::NEW, Status::ACTIVE])
  end
end
