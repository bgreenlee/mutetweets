# base class for mentions and direct messages
class Tweet
  attr_reader :id, :created_at, :text, :muter, :mutee, :length, :direct_message, :verbose

  # time unit multpliers
  UNITS = {'m' => 60, 'h' => 3600, 'd' => 86400}

  def initialize(params)
    @id = params["id"]
    @created_at = Time.parse(params["created_at"]) rescue $stderr.puts("invalid time: #{params['created_at']}") && nil
    @text = params["text"]
    @mutee = nil
    @length = nil
    @direct_message = false
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
