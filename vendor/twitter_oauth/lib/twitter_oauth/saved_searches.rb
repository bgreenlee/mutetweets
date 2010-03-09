module TwitterOAuth
  class Client
    
    # Returns the authenticated user's saved search queries.
    def saved_searches
      get("/saved_searches")
    end
    
    # Retrieve the data for a saved search owned by the authenticating user specified by the given id.
    def get_saved_search(search_id)
      get("/saved_searches/show/#{search_id}")
    end
    
    # Creates a saved search for the authenticated user.
    def create_saved_search(query)
      post("/saved_searches/create", :query => query)
    end
    
    def delete_saved_search(search_id)
      post("/saved_searches/destroy/#{search_id}")
    end
    
  end
end