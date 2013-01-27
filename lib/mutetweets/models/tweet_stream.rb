class TweetStream
  include DataMapper::Resource
  
  property :last_mention_id, String, :length => 20, :key => true
  property :last_direct_message_id, String, :length => 20, :key => true
end