# base class for mentions and direct messages
class Tweet
  attr_reader :id, :created_at, :text, :muter, :mutee, :length, :direct_message

  # time unit multpliers
  UNITS = {'s' => 1, 'm' => 60, 'h' => 3600, 'd' => 86400}

  def initialize(params)
    @id = params["id"]
    @created_at = Time.parse(params["created_at"]) rescue $stderr.puts("invalid time: #{params['created_at']}") && nil
    @text = params["text"]
    @mutee = nil
    @length = nil
    @direct_message = false
    # parse the text
    parse!
  end

  # parse the tweet for a valid mute
  def parse!
    if m = /@mutetweets\s+@(\w+)\s+(?:for)?\s*(\d+)(s|m|h|d)/i.match(@text)
      @mutee = m[1]
      @length = m[2].to_i * UNITS[m[3]]
    end
  end

  # return true if this is a valid mute
  def valid_mute?
    @created_at && @mutee && @length
  end
  
  def direct_message?
    direct_message
  end
  
  def to_s
    "[#{@id}] #{@muter}: #{@text}"
  end
end
