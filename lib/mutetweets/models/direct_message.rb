class DirectMessage < Tweet
  def initialize(params)
    @muter = params["sender"]["screen_name"]
    super
  end
  
  # parse the tweet for a valid mute
  def parse!
    if m = /@(\w+)\s+(?:for)?\s*(\d+)(s|m|h|d)/i.match(@text)
      @mutee = m[1]
      @length = m[2].to_i * UNITS[m[3]]
      @direct_message = true
    end
  end
end
