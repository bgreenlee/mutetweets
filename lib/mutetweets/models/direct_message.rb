class DirectMessage < Tweet
  def initialize(params)
    @muter = params.sender.screen_name
    super
    parse!
  end

  # parse the tweet for a valid mute
  def parse!
    if m = /^\s*@?(\w+)\s+(?:for)?\s*(\d+)(m|h|d)(?:\s+-(v|verbose)\b)?/i.match(@text)
      @mutee = m[1]
      @length = m[2].to_i * UNITS[m[3].downcase]
      @verbose = %w{v verbose}.include?(m[4])
      @direct_message = true
    end
  end
end
