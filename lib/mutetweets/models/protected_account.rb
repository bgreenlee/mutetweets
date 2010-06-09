# table to track ids of users with protected accounts, so we don't keep trying to friend them
class ProtectedAccount
  include DataMapper::Resource

  property :id, Serial
  property :twitter_id, Integer
end