require 'twitter'

module MuteTweets
  include Logger

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
      logger.debug "processing mutes..."
      mutes = get_mutes
      mutes.each do |mute|
        logger.info "mute: #{mute}"

        # skip any invalid and expired mutes
        expires_at = nil

        begin
          expires_at = mute.created_at + mute.length
        rescue RangeError
          logger.warn "invalid time! skipping..."
          next
        end

        if expires_at < Time.now
          logger.info "mute expired! skipping..."
          next
        end

        user = User.first(:screen_name => mute.muter) || User.create(:screen_name => mute.muter)
        # make sure there isn't an active mute already
        if Mute.active_mute?(user, mute.mutee)
          logger.warn "already have a new/active mute for #{mute.muter}/#{mute.mutee}! skipping..."
          next
        else
          # create the mute
          Mute.create(:user => user, :screen_name => mute.mutee, :expires_at => expires_at,
                      :direct_message => mute.direct_message, :verbose => mute.verbose)
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
      logger.info "valid mutes: #{mutes.length}" if mutes.any?
      return mutes
    end

    def get_mutes_from_mentions
      # get mentions
      options = {:count => MAX_FETCH}
      options[:since_id] = @tweet_stream.last_mention_id unless @tweet_stream.last_mention_id.blank?
      mentions = @client.mentions(options).map {|m| Mention.new(m) }

      if mentions.any?
        @last_mention_id = mentions.first.id
        logger.info "new mentions: #{mentions.length}"
        logger.debug "last mention id: #{@last_mention_id}"
      end

      return mentions.select {|m| m.valid_mute? }
    end

    def get_mutes_from_direct_messages
      # get direct mesages
      options = {:count => MAX_FETCH}
      options[:since_id] = @tweet_stream.last_direct_message_id unless @tweet_stream.last_direct_message_id.blank?
      messages = @client.direct_messages(options).map {|m| DirectMessage.new(m) }
      if messages.any?
        @last_direct_message_id = messages.first.id
        logger.info "new direct messages: #{messages.length}"
        logger.debug "last direct message id: #{@last_direct_message_id}"
      end
      return messages.select {|m| m.valid_mute? }
    end

    def process_unfollows
      Mute.to_unfollow.each do |m|
        user = m.user
        next unless user.registered? # can't do anything if the user isn't registered
        logger.info "unfollowing #{m.screen_name} for #{user.screen_name}"
        user_client = @client.for_user(user)
        begin
          response = user_client.unfollow(m.screen_name)
          m.activate!
          @client.send_message(user, "Muted #{m.screen_name}") if m.verbose?
        rescue Twitter::Error::NotFound => e
          m.error!(e.message)
        rescue Twitter::Error::Unauthorized => e
          user.clear_tokens!
          @client.send_message(user, MESSAGE[:invalid_creds])
        end
      end
    end

    def process_refollows
      Mute.to_refollow.each do |m|
        user = m.user
        next unless user.registered? # can't do anything if the user isn't registered
        logger.info "refollowing #{m.screen_name} for #{user.screen_name}"
        user_client = @client.for_user(user)
        begin
          response = user_client.follow(m.screen_name)
          if response["error"]
            err_msg = response["error"]
            case err_msg
            when /already on your list/i
              # just ignore
              logger.info "#{user.screen_name} was already following #{m.screen_name}"
              m.expire!
            else
              logger.error "error: #{err_msg}"
              msg = "error friending #{m.screen_name}: #{err_msg}"
              m.retries += 1
              if m.retries > MAX_RETRIES
                logger.error "#{msg} (giving up)"
                m.error!(err_msg)
              else
                logger.error "#{msg} (attempt ##{m.retries})"
                m.save
              end
            end
          else
            m.expire!
            @client.send_message(user, "Unmuted #{m.screen_name}") if m.verbose?
          end
        rescue Twitter::Error::Unauthorized => e
          user.clear_tokens!
          @client.send_message(user, MESSAGE[:invalid_creds])
        rescue Twitter::Error::Forbidden => e
          # the user has blocked us (or the user). Ignore them.
          logger.info "#{m.screen_name} seems to be blocking #{user.screen_name} (#{e.message})"
          m.expire!
        rescue Twitter::Error::NotFound => e
          logger.info "#{m.screen_name} or #{user.screen_name} seems to be gone? (#{e.message})"
          m.expire!
        end
      end
    end

    def update_last_ids
      @tweet_stream.last_mention_id = @last_mention_id if @last_mention_id
      @tweet_stream.last_direct_message_id = @last_direct_message_id if @last_direct_message_id
      @tweet_stream.save if @last_mention_id || @last_direct_message_id
    end
  end
end
