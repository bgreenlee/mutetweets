class Mention < Tweet
  def initialize(params)
    @muter = params["user"]["screen_name"]
    super
    parse!
  end

  # parse the tweet for a valid mute
  def parse!
    if m = /@mutetweets\s+@(\w+)\s+(?:for)?\s*(\d+)(m|h|d)(?:\s+-(v|verbose)\b)?/i.match(@text)
      @mutee = m[1]
      @length = m[2].to_i * UNITS[m[3]]
      @verbose = %w{v verbose}.include?(m[4])
    end
  end
end
