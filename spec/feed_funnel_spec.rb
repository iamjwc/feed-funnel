require 'spec/spec_helper'

describe "With simple feeds" do
  before do
    @master_feed = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
    @other_feed  = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))

    @combined_feed_regex = /enclosure.*episode1.*enclosure.*media:group.*media:content.*episode1.*media:content.*media:content.*episode1.*media:content.*media:group/
  end

  describe FeedFunnel::LevenshteinFunnel do
    before do
      @funnel_on_description = FeedFunnel::LevenshteinFunnel.new(@master_feed) {|i| (i.h % :description).inner_text }
    end
  
    it "should be able to combine 2 simple feeds on a description" do
      @funnel_on_description.funnel(@other_feed).to_s.should match(@combined_feed_regex)
    end
  end
  
  describe FeedFunnel::DirectMatchFunnel do
    before do
      @funnel_on_filename_with_extension    = FeedFunnel::DirectMatchFunnel.new(@master_feed) {|i| (i.h % :enclosure)[:url] }
      @funnel_on_filename_without_extension = FeedFunnel::DirectMatchFunnel.new(@master_feed) {|i| (i.h % :enclosure)[:url].gsub(/\..*$/, "") }
    end
  
    it "should be able to combine 2 simple feeds on a filename without extension" do
      @funnel_on_filename_without_extension.funnel(@other_feed).to_s.should match(@combined_feed_regex)
    end
  
    it "should not be able to combine 2 simple feeds on a filename with extension" do
      @funnel_on_filename_with_extension.funnel(@other_feed).to_s.should_not match(@combined_feed_regex)
    end
  end
end
