require 'time'

# base class for mentions and direct messages
class Tweet
  attr_reader :id, :created_at, :text, :muter, :mutee, :length, :direct_message, :verbose

  # time unit multpliers
  UNITS = {'m' => 60, 'h' => 3600, 'd' => 86400}

  def initialize(params)
    @id = params.id
    begin
      @created_at = params.created_at.kind_of?(Time) ? params.created_at : Time.parse(params.created_at)
    rescue Exception => e
      $stderr.puts("invalid time: #{params.created_at}\nError: #{e.message}")
      @created_at = nil
    end
    @text = params.text
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
