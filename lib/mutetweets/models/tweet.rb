# base class for mentions and direct messages
class Tweet
  attr_reader :id, :text, :muter, :mutee, :length

  # time unit multpliers
  UNITS = {'s' => 1, 'm' => 60, 'h' => 3600, 'd' => 86400}

  def initialize(params)
    @id = params["id"]
    @text = params["text"]
    @mutee = nil
    @length = nil
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
    @mutee && @length
  end
end
