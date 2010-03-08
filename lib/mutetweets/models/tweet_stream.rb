class TweetStream
  include DataMapper::Resource
  
  property :last_mention_id, String, :key => true
  property :last_direct_message_id, String, :key => true
end