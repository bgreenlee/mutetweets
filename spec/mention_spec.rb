require 'spec_helper'

describe Mention do

  it "should parse valid mutes" do
    mutes = ["@mutetweets @loudmouth 42m",
             "@mutetweets loudmouth 42h",
             "@mutetweets @loudmouth 42d",
             "@mutetweets loudmouth for 42m",
             "@mutetweets @loudmouth 42m -v",
             "@mutetweets loudmouth 42m -verbose"
            ]
    for mute in mutes
      mention = mention_with_text(mute)
      mention.mutee.should == "loudmouth"
    end
  end

  it "should parse minutes" do
    mention = mention_with_text("@mutetweets @loudmouth 42m")
    mention.length.should == 42 * 60
  end

  it "should parse hours" do
    mention = mention_with_text("@mutetweets @loudmouth 42h")
    mention.length.should == 42 * 3600
  end

  it "should parse days" do
    mention = mention_with_text("@mutetweets @loudmouth 42d")
    mention.length.should == 42 * 86400
  end

  it "should recognize a valid verbose mute" do
    for text in ["@mutetweets @x 1m -v", "@mutetweets @x 1m -verbose"]
      mention = mention_with_text(text)
      mention.verbose.should be_true
    end
  end

  def mention_with_text(text)
      tweet_params = {
          "id" => 1234567890,
          "user" => { "screen_name" => "joeblow" },
          "created_at" => "Fri Apr 16 17:55:46 +0000 2010",
          "text" => text
      }
      Mention.new(tweet_params)
  end
end
