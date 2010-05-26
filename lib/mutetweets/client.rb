module MuteTweets
  include Logger

  class Client < TwitterOAuth::Client
    attr_reader :client, :follower_ids

    # create a new client instance. If a user is provided, log in as that user.
    # Otherwise, log in as mutetweets
    def initialize(config, user = nil)
      @config = config
      @user = user

      options = {
        :consumer_key => config['consumer_key'],
        :consumer_secret => config['consumer_secret'],
        :token => user ? user.access_token : config['client_access_token'],
        :secret => user ? user.secret_token : config['client_secret_token']
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
      followers = followers_ids
      logger.debug "followers: #{followers.length}"
      friends = friends_ids
      logger.debug "friends: #{friends.length}"
      if followers.is_a?(Array) && friends.is_a?(Array)
        if followers.empty?
          # This seems to have happened at least once. I suspect a Twitter hiccup. Ignore this to be
          # safe, since it will cause us to unfriend everyone and then refriend the next time it runs.
          # No need to check for empty friends, since Twitter ignores attempts to friend someone you've
          # already friended.
          logger.warn "hmm...no followers. ignoring."
        else
          to_friend = followers - friends
          to_unfriend = friends - followers

          to_unfriend.each {|id| unfriend(id) }
          logger.info "unfriended #{to_unfriend.length}" if to_unfriend.any?
          to_friend.each {|id| friend(id) }
          logger.info "friended #{to_friend.length}" if to_friend.any?

          @follower_ids = followers
        end
      else
        logger.error "unexpected response: followers: #{followers.inspect} friends: #{friends.inspect}"
      end
    end

    def is_follower?(user)
      follower_ids.include?(user.twitter_id)
    end

    # message the user; if they're a follower, send a DM; otherwise, a public message
    def send_message(user, message)
      if is_follower?(user)
        logger.info "sending direct message to #{user.screen_name}: #{message}"
        response = message(user.screen_name, message)
      else
        logger.info "sending public message to #{user.screen_name}: #{message}"
        response = update("@#{user.screen_name} #{message}")
      end
      if response['error']
        logger.error "error sending message: #{response['error']}"
      end
    end
  end
end
