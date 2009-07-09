require 'spec/spec_helper'

describe FeedFunnel::LevenshteinFunnel do
  before do
    @master_feed = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
    @other_feed  = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))

    @funnel_on_description = FeedFunnel::LevenshteinFunnel.new(@master_feed) {|i| (i.h % :description).inner_text }
  end

  it "should be able to combine 2 simple feeds on a description" do
    @funnel_on_description.funnel(@other_feed).to_s.should match(
      /#{%w{
        enclosure
        episode1
        enclosure
        media:group
        media:content
        episode1
        media:content
        media:content
        episode1
        media:content
        media:group
      }.join('.*')}/
    )
  end
end
