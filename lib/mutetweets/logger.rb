module MuteTweets
  LOG_FILE = "#{File.dirname(__FILE__)}/../../log/mutetweets.log"

  module Logger
    extend self    
    def logger
      @@logger ||= begin
        logger = set_log_output(MuteTweets::LOG_FILE)
        logger.level = ::Logger::INFO
        logger
      end
    end
    
    def set_log_output(io)
      @@logger = ::Logger.new(io)
      @@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @@logger
    end
    
    def set_log_level(level)
      logger.level = ::Logger.const_get(level.to_s.upcase)
    end
  end
end

  