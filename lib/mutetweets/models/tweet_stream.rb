class TweetStream
  include DataMapper::Resource
  
  property :last_mention_id, String, :key => true
  property :last_direct_message_id, String, :key => true
  
  # process new mutes
  def self.process!(client)
    tweet_stream = first || new

    # get mentions
    options = {:count => 200}
    options[:since_id] = tweet_stream.last_mention_id unless tweet_stream.last_mention_id.blank?
    mentions = client.mentions(options).map {|m| Mention.new(m) }
    mutes = mentions.select {|m| m.valid_mute? }
    
    # get direct mesages
    options = {:count => 200}
    options[:since_id] = tweet_stream.last_direct_message_id unless tweet_stream.last_direct_message_id.blank?
    messages = client.messages(options).map {|m| DirectMessage.new(m) }
    mutes += messages.select {|m| m.valid_mute? }
    
    mutes.each do |mute|
      user = User.first(:screen_name => mute.muter) || User.create(:screen_name => mute.muter)
      Mute.create(:user => user, :screen_name => mute.mutee, :expires_at => Time.now + mute.length)
      # if the user doesn't have tokens, send a message with a login link (only send it once, though)
      if !user.registered? && !user.welcome_sent?
        client.update("@#{user.screen_name} Welcome to Mute Tweets! Go to http://mutetweets.com to get started.")
        user.update(:welcome_sent => true)
      end
    end

    # unfollow
    to_unfollow = Mute.all(:expires_at.gte => Time.now, :unfollowed => false)
    to_unfollow.each do |m|
      client.unfriend(m.screen_name)
      m.update(:unfollowed => true)
    end
    
    # refollow
    to_refollow = Mute.all(:expires_at.lte => Time.now, :refollowed => false)
    to_refollow.each do |m|
      client.friend(m.screen_name)
      m.update(:refollowed => true)
    end
    
    # update last_ids
    tweet_stream.last_mention_id = mentions.last.id if mentions.any?
    tweet_stream.last_direct_message_id = messages.last.id if messages.any?
    tweet_stream.save if mentions.any? || messages.any?
  end
end