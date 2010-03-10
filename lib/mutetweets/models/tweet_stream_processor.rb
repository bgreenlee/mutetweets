class TweetStreamProcessor
  MAX_FETCH = 200 # max number of messages to fetch from Twitter
  MAX_RETRIES = 3 # number of times to retry in the case of an error
  MESSAGE = {
    :welcome => "Welcome to Mute Tweets! Go to http://mutetweets.com to get started.",
    :unregistered => "Sorry, I don't have you registered yet. Go to http://mutetweets.com to get started.",
    :invalid_creds => "Sorry, it seems the credentials I have for you are invalid. Go to http://mutetweets.com to reconnect."
  }

  def initialize(client, verbose = false)
    @client = client
    @verbose = verbose
    @tweet_stream = TweetStream.first || TweetStream.new
    @last_mention_id = @last_direct_message_id = nil
  end

  # process new mutes
  def process
    process_mutes
    process_unfollows
    process_refollows
    update_last_ids
  end
  
  private
  
  def process_mutes
    mutes = get_mutes
    mutes.each do |mute|
      say "Mute: #{mute}"
      # skip any expired mutes
      expires_at = mute.created_at + mute.length
      if expires_at < Time.now
        say "Mute expired! Skipping..."
        next
      end
      
      user = User.first(:screen_name => mute.muter) || User.create(:screen_name => mute.muter)
      # make sure there isn't an active mute already
      if Mute.active_mute?(user, mute.mutee)
        say "Already have a new/active mute for #{mute.muter}/#{mute.mutee}! Skipping..."
        next
      else
        # create the mute
        Mute.create(:user => user, :screen_name => mute.mutee, :expires_at => expires_at, :direct_message => mute.direct_message)
        # if the user doesn't have tokens, send a message with a login link (only send it once, though)
        unless user.registered?
          @client.send_message(user, user.welcome_sent? ? MESSAGE[:unregistered] : MESSAGE[:welcome])
          user.update(:welcome_sent => true)
        end
      end
    end
  end
  
  def get_mutes
    mutes = get_mutes_from_mentions + get_mutes_from_direct_messages
    say "Got #{mutes.length} valid mutes."
    return mutes
  end
  
  def get_mutes_from_mentions
    # get mentions
    options = {:count => MAX_FETCH}
    options[:since_id] = @tweet_stream.last_mention_id unless @tweet_stream.last_mention_id.blank?
    mentions = @client.mentions(options).map {|m| Mention.new(m) }

    say "Got #{mentions.length} new mentions."
    if mentions.any?
      @last_mention_id = mentions.first.id
      say "Last mention id: #{@last_mention_id}"
    end
    
    return mentions.select {|m| m.valid_mute? }
  end
  
  def get_mutes_from_direct_messages
    # get direct mesages
    options = {:count => MAX_FETCH}
    options[:since_id] = @tweet_stream.last_direct_message_id unless @tweet_stream.last_direct_message_id.blank?
    messages = @client.messages(options).map {|m| DirectMessage.new(m) }    
    say "Got #{messages.length} new direct messages."
    if messages.any?
      @last_direct_message_id = messages.first.id
      say "Last direct message id: #{@last_direct_message_id}"
    end
    return messages.select {|m| m.valid_mute? }
  end
  
  def process_unfollows
    to_unfollow = Mute.all(:expires_at.gte => Time.now, :status => Mute::Status::NEW)
    to_unfollow.each do |m|
      user = m.user
      next unless user.registered? # can't do anything if the user isn't registered
      say "Unfollowing #{m.screen_name} for #{user.screen_name}"
      user_client = @client.for_user(user)
      response = user_client.unfriend(m.screen_name)
      # if the user isn't friends with the mutee, or the mutee doesn't exist, delete the mute
      if response["error"]
        err_msg = response["error"]
        say "Error: #{err_msg}"
        case err_msg
        when /not (found|friends)/i
          m.update(:status => Mute::Status::ERROR, :error => err_msg)
        when /Could not authenticate/i
          user.clear_tokens!
          @client.send_message(user, MESSAGE[:invalid_creds])
        else
          msg = "Error unfriending #{m.screen_name}: #{err_msg}"
          m.retries += 1
          if m.retries > MAX_RETRIES
            error "#{msg} (giving up)"
            m.update(:status => Mute::Status::ERROR, :error => err_msg)
          else
            error "#{msg} (attempt ##{m.retries})"
            m.save
          end
        end
      else
        m.update(:status => Mute::Status::ACTIVE)
      end
    end
  end
  
  def process_refollows
    to_refollow = Mute.all(:expires_at.lte => Time.now, :status => Mute::Status::ACTIVE)
    to_refollow.each do |m|
      user = m.user
      next unless user.registered? # can't do anything if the user isn't registered
      say "Refollowing #{m.screen_name} for #{user.screen_name}"
      user_client = @client.for_user(user)
      response = user_client.friend(m.screen_name)
      if response["error"]
        err_msg = response["error"]
        case err_msg
        when /already on your list/i
          # just ignore
        when /Could not authenticate/i
          user.clear_tokens!
          @client.send_message(user, MESSAGE[:invalid_creds])
        else
          say "Error: #{err_msg}"
          msg = "Error friending #{m.screen_name}: #{err_msg}"
          m.retries += 1
          if m.retries > MAX_RETRIES
            error "#{msg} (giving up)"
            m.update(:status => Mute::Status::ERROR, :error => err_msg)
          else
            error "#{msg} (attempt ##{m.retries})"
            m.save
          end
        end
      else
        m.update(:status => Mute::Status::EXPIRED)
      end
    end
  end
  
  def update_last_ids
    @tweet_stream.last_mention_id = @last_mention_id if @last_mention_id
    @tweet_stream.last_direct_message_id = @last_direct_message_id if @last_direct_message_id
    @tweet_stream.save if @last_mention_id || @last_direct_message_id
  end
  
  def say(msg)
    puts msg if @verbose
  end
  
  def error(msg)
    $stderr.puts msg
  end
end