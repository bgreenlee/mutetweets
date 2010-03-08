class Mention < Tweet
  def initialize(params)
    @muter = params["user"]["screen_name"]
    super
  end
end
