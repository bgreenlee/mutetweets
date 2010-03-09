module TwitterOAuth
  class Client
    
    # Returns a single status, specified by the id parameter below.
    def status(id)
      get("/statuses/show/#{id}")
    end
    
    # Updates the authenticating user's status.
    def update(message, options={})
      post('/statuses/update', options.merge(:status => message))
    end

    # Destroys the status specified by the required ID parameter
    def status_destroy(id)
      post("/statuses/destroy/#{id}")
    end
    
    # Retweets the tweet specified by the id parameter. Returns the original tweet with retweet details embedded.
    def retweet(id)
      post("/statuses/retweet/#{id}")
    end
    
  end
end
