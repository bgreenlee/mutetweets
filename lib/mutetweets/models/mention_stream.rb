# table for tracking the last id we processed in our mention stream
class MentionStream
  include DataMapper::Resource
  
  property :last_id, Integer, :key => true, :default => 0
end