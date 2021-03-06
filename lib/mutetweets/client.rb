require 'twitter'

module MuteTweets
  include Logger

  class Client < Twitter::REST::Client
    attr_reader :client, :cached_follower_ids

    # create a new client instance. If a user is provided, log in as that user.
    # Otherwise, log in as mutetweets
    def initialize(config, user = nil)
      @config = config
      @user = user

      options = {
        :consumer_key => config['consumer_key'],
        :consumer_secret => config['consumer_secret'],
        :access_token => user ? user.access_token : config['client_access_token'],
        :access_token_secret => user ? user.secret_token : config['client_secret_token']
      }

      super(options)
    end

    # return a new client for the given user
    def for_user(user)
      self.class.new(@config, user)
    end

    def sync_followers!
      # this should never be run for any user other than mutetweets
      raise "Refusing to sync #{@user.screen_name}'s followers!" if @user

      logger.debug "syncing followers"

      # process followers
      # we need to sync our followers and friends--friending people who are following us and unfriending people who are no longer following us
      followers = follower_ids.to_a
      logger.debug "followers: #{followers.length}"
      friends = friend_ids.to_a
      logger.debug "friends: #{friends.length}"
      if followers.is_a?(Array) && friends.is_a?(Array)
        if followers.empty?
          # This seems to have happened at least once. I suspect a Twitter hiccup. Ignore this to be
          # safe, since it will cause us to unfriend everyone and then refriend the next time it runs.
          # No need to check for empty friends, since Twitter ignores attempts to friend someone you've
          # already friended.
          logger.warn "hmm...no followers. ignoring."
        else
          to_follow = followers - friends
          to_unfollow = friends - followers
          unfollow(to_unfollow)
          logger.info "unfollowed #{to_unfollow.length} (#{to_unfollow.join(', ')})" if to_unfollow.any?
          if to_follow.any?
            # remove our pending follow requests, so we don't try to re-follow
            to_follow -= friendships_outgoing.to_a
            follow(to_follow)
          end

          @cached_follower_ids = followers
        end
      else
        logger.error "unexpected response: followers: #{followers.inspect} friends: #{friends.inspect}"
      end
    end

    def is_follower?(user)
      @cached_follower_ids ||= follower_ids.to_a
      @cached_follower_ids.include?(user.twitter_id.to_i)  # FIXME: this will need to be changed when follower_ids returns strings, as it should
    end

    # message the user; if they're a follower, send a DM; otherwise, a public message
    def send_message(user, message)
      # append the time to the message so twitter doesn't complain to us about duplicate statuses
      message += " (at #{Time.now})"
      begin
        if is_follower?(user)
          logger.info "sending direct message to #{user.screen_name}: #{message}"
          response = direct_message_create(user.screen_name, message)
        else
          logger.info "sending public message to #{user.screen_name}: #{message}"
          response = update("@#{user.screen_name} #{message}")
        end
      rescue Twitter::Error => e
        logger.error "error sending message: #{e.message}"
      end
    end
  end
end
