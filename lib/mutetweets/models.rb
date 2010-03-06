require 'dm-core'
require 'dm-timestamps'

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