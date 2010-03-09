module MuteTweets
  class Client < TwitterOAuth::Client
    attr_reader :client
    
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
      else  
        $stderr.puts "Unexpected response:\nfollowers: #{followers.inspect}\n\nfriends: #{friends.inspect}"
      end
    end
  end
end
