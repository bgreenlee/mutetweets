class TweetStream
  include DataMapper::Resource
  
  MAX_RETRIES = 3
  WELCOME_MESSAGE = "Welcome to Mute Tweets! Go to http://mutetweets.com/connect to get started."
  
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
      # skip any expired mutes
      expires_at = mute.created_at + mute.length
      next if expires_at > Time.now
      
      user = User.first(:screen_name => mute.muter) || User.create(:screen_name => mute.muter)
      # make sure there isn't an active mute already
      unless Mute.first(:user => user, :screen_name => mute.mutee, :status => Mute::Status::ACTIVE)
        Mute.create(:user => user, :screen_name => mute.mutee, :expires_at => expires_at, :direct_message => mute.direct_message)
        # if the user doesn't have tokens, send a message with a login link (only send it once, though)
        if !user.registered? && !user.welcome_sent?
          if mute.direct_message?
            client.message(user.screen_name, WELCOME_MESSAGE)
          else
            client.update("@#{user.screen_name} #{WELCOME_MESSAGE}")
          end
          user.update(:welcome_sent => true)
        end
      end
    end

    # unfollow
    to_unfollow = Mute.all(:expires_at.gte => Time.now, :status => Mute::Status::NEW)
    to_unfollow.each do |m|
      response = client.unfriend(m.screen_name)
      # if the user isn't friends with the mutee, or the mutee doesn't exist, delete the mute
      if response["error"]
        if response["error"] =~ /not (found|friends)/i
          m.update(:status => Mute::Status::ERROR, :error => resonse['error'])
        else
          msg = "[client.unfriend] Error unfriending #{m.screen_name}: #{response['error']}"
          m.retries += 1
          if m.retries > MAX_RETRIES
            $stderr.puts "#{msg} (giving up)"
            m.update(:status => Mute::Status::ERROR, :error => response['error'])
          else
            $stderr.puts "#{msg} (attempt ##{m.retries})"
            m.save
          end
        end
      else
        m.update(:status => Mute::Status::ACTIVE)
      end
    end
    
    # refollow
    to_refollow = Mute.all(:expires_at.lte => Time.now, :status => Mute::Status::ACTIVE)
    to_refollow.each do |m|
      response = client.friend(m.screen_name)
      if response["error"] && response["error"] !~ /already on your list/i          
        msg = "[client.unfriend] Error friending #{m.screen_name}: #{response['error']}"
        m.retries += 1
        if m.retries > MAX_RETRIES
          $stderr.puts "#{msg} (giving up)"
          m.update(:status => Mute::Status::ERROR, :error => response['error'])
        else
          $stderr.puts "#{msg} (attempt ##{m.retries})"
          m.save
        end
      else
        m.update(:status => Mute::Status::EXPIRED)
      end
    end
    
    # update last_ids
    tweet_stream.last_mention_id = mentions.first.id if mentions.any?
    tweet_stream.last_direct_message_id = messages.first.id if messages.any?
    tweet_stream.save if mentions.any? || messages.any?
  end
end