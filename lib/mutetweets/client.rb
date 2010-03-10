module MuteTweets
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
      
      # process followers
      # we need to sync our followers and friends--friending people who are following us and unfriending people who are no longer following us
      followers = followers_ids
      friends = friends_ids
      if followers.is_a?(Array) && friends.is_a?(Array)
        to_friend = followers - friends
        to_unfriend = friends - followers

        to_unfriend.each {|id| unfriend(id) }
        to_friend.each {|id| friend(id) }
        
        @follower_ids = followers
      else  
        $stderr.puts "Unexpected response:\nfollowers: #{followers.inspect}\n\nfriends: #{friends.inspect}"
      end
    end
    
    def is_follower?(user)
      follower_ids.include?(user.twitter_id)
    end
    
    # message the user; if they're a follower, send a DM; otherwise, a public message
    def send_message(user, message)
      if is_follower?(user)
        say "Sending direct message to #{user.screen_name}: #{message}"
        @client.message(user.screen_name, message)
      else
        say "Sending public message to #{user.screen_name}: #{message}"
        @client.update("@#{user.screen_name} #{message}")
      end
    end
  end
end
