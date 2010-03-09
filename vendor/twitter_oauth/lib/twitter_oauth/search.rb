require 'open-uri'

module TwitterOAuth
  class Client
    
    def search(q, options={})
      options[:page] ||= 1
      options[:per_page] ||= 20
      options[:q] = URI.escape(q)
      search_get("/search", options)
    end
    
    # Returns the current top 10 trending topics on Twitter.
    def current_trends
      search_get("/trends/current")
    end
    
    # Returns the top 20 trending topics for each hour in a given day.
    def daily_trends
      search_get("/trends/daily")
    end
    
    # Returns the top 30 trending topics for each day in a given week.
    def weekly_trends
      search_get("/trends/weekly")
    end
    
    private
      def search_get(path, options)
        args = options.map{|k,v| "#{k}=#{v}"}.join('&')
        path << "?#{args}"
        response = open('http://search.twitter.com' + path, 'User-Agent' => 'github.com/moomerman/twitter_outh')
        JSON.parse(response.read)
      end
  end
end