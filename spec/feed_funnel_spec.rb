require 'spec/spec_helper'

describe "With simple feeds" do
  before do
    @master_feed    = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
    @other_feed     = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))
    @different_feed = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_different.rss"))

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

  describe FeedFunnel::DateProximityFunnel do
    before do
      @funnel_on_pubdate = FeedFunnel::DateProximityFunnel.new(@master_feed) {|i| (i.h % :pubDate).inner_text }
    end
  
    it "should be able to combine 2 simple feeds on a filename without extension" do
      @funnel_on_pubdate.funnel(@other_feed).to_s.should match(@combined_feed_regex)
      (Hpricot::XML(@funnel_on_pubdate.funnel(@other_feed).to_s) / :item).size.should == 1
    end

    it "should not be able to combine 2 different feeds on a filename without extension" do
      (Hpricot::XML(@funnel_on_pubdate.funnel(@different_feed).to_s) / :item).size.should == 2
    end
  end
end

def strip_html(s)
  s.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub!(/<[^>]*>/, "").gsub!(/\W+/, " ")
end

# describe "With alaska feeds" do
#   before do
#     @master_rss  = File.read("spec/rss/alaska_hdtv.rss")
#     @other_rss   = File.read("spec/rss/alaska_podshow.rss")
#     @master_feed = FeedFunnel::Feed.new(@master_rss)
#     @other_feed  = FeedFunnel::Feed.new(@other_rss)
#   end
# 
#   describe FeedFunnel::DateProximityFunnel do
#     before do
#       @funnel_on_pubdate = FeedFunnel::DateProximityFunnel.new(@master_feed) {|i| (i.h % :pubDate).inner_text }
#       @funnel_on_description = FeedFunnel::LevenshteinFunnel.new(@master_feed) {|i| strip_html((i.h % :description).inner_text) }
#     end
# 
#     it "shouldn't lose any media urls" do
#       h = Hpricot::XML(@funnel_on_description.funnel(@other_feed).to_s)
# 
#       media_content_tags = (h / :"media:content").size
#       content_tags = (Hpricot::XML(@master_rss) / :"media:content") + (Hpricot::XML(@other_rss) / :"media:content")
# 
#       media_content_tags.should == content_tags.size
#     end
#   end
# end

describe "With moremi feeds" do
  before do
    @master_feed = FeedFunnel::Feed.new(File.read("spec/rss/moremi_podcast_720.rss"))
    @other_feed  = FeedFunnel::Feed.new(File.read("spec/rss/moremi_podcast_ipod.rss"))
  end

  describe FeedFunnel::DateProximityFunnel do
    before do
      @funnel_on_pubdate = FeedFunnel::DateProximityFunnel.new(@master_feed) {|i| (i.h % :pubDate).inner_text }
      @funnel_on_description = FeedFunnel::LevenshteinFunnel.new(@master_feed) {|i| strip_html((i.h % :description).inner_text) }
      @funnel_on_title = FeedFunnel::DirectMatchFunnel.new(@master_feed) {|i| (i.h % :title).inner_text }
    end
  
    it "should be able to combine 2 simple feeds on a filename without extension" do
      media_content_tags = (Hpricot::XML(@funnel_on_title.funnel(@other_feed).to_s) / :item).map {|item| (item / :"media:content").size }
      sum = media_content_tags.inject(0) {|s, i| s + i }
      
      sum.should be > media_content_tags.size
    end
  end
end

