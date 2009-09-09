require 'spec/spec_helper'

def strip_html(s)
  s.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/<[^>]*>/, "").gsub(/\W+/, " ")
end

def count_media_urls(rss)
  (Hpricot::XML(rss.to_s) / :"media:content").size
end

def count_media_urls_in(item)
  (item / :"media:content").size
end

def count_items(rss)
  (Hpricot::XML(rss.to_s) / :item).size
end

describe "With simple feeds" do
  before do
    @master_feed    = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
    @other_feed     = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))
    @different_feed = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_different.rss"))

    @combined_feed_regex = /enclosure.*episode1.*enclosure.*media:group.*media:content.*episode1.*media:content.*media:content.*episode1.*media:content.*media:group/
  end

  describe FeedFunnel::LevenshteinMatcher do
    before do
      @funnel_on_description = FeedFunnel::Funnel.new(@master_feed,
        :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| (i.h % :description).inner_text }],
        :feeds => [@other_feed]
      )
    end
  
    it "should be able to combine 2 simple feeds on a description" do
      @funnel_on_description.GO!.to_s.should match(@combined_feed_regex)
    end
  end

  describe FeedFunnel::DirectMatcher do
    before do
      @funnel_on_filename_with_extension = FeedFunnel::Funnel.new(@master_feed,
        :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :enclosure)[:url] }],
        :feeds => [@other_feed]
      )

      @funnel_on_filename_without_extension = FeedFunnel::Funnel.new(@master_feed)
      @funnel_on_filename_without_extension.matchers << FeedFunnel::DirectMatcher.new {|i| (i.h % :enclosure)[:url].gsub(/\..*$/, "") }
      @funnel_on_filename_without_extension.feeds << @other_feed
    end

    it "should be able to combine 2 simple feeds on a filename without extension" do
      @funnel_on_filename_without_extension.GO!.to_s.should match(@combined_feed_regex)
    end

    it "should not be able to combine 2 simple feeds on a filename with extension" do
      @funnel_on_filename_with_extension.GO!.to_s.should_not match(@combined_feed_regex)
    end
  end

  describe FeedFunnel::DateProximityMatcher do
    before do
      @funnel_on_pubdate = FeedFunnel::Funnel.new(@master_feed)
      @funnel_on_pubdate.matchers << FeedFunnel::DateProximityMatcher.new {|i| (i.h % :pubDate).inner_text }
      @funnel_on_pubdate.feeds << @other_feed

			@funneled_on_pubdate = @funnel_on_pubdate.GO!.to_s
    end
  
    it "should be able to combine 2 simple feeds on by pubdate" do
      @funneled_on_pubdate.should match(@combined_feed_regex)
      (Hpricot::XML(@funneled_on_pubdate) / :item).size.should == 1
    end
  end
end

describe "With short moremi feeds" do
  before do
    @master_rss = File.read("spec/rss/moremi_podcast_720_short.rss")
    @other_rss  = File.read("spec/rss/moremi_podcast_ipod_short.rss")
    @master_feed = FeedFunnel::Feed.new(@master_rss)
    @other_feed  = FeedFunnel::Feed.new(@other_rss)
  end

  describe FeedFunnel::Funnel do
    before do
      @funneled_on_description = FeedFunnel::Funnel.new(@master_feed,
																												:matchers => [FeedFunnel::LevenshteinMatcher.new {|i| strip_html((i.h % :description).inner_text) }],
																												:feeds    => [@other_feed]).GO!.to_s
      @funneled_on_title = FeedFunnel::Funnel.new(@master_feed,
																												:matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
																												:feeds    => [@other_feed]).GO!.to_s
    end

    it "shouldn't lose any media urls" do
      media_urls_sum      = count_media_urls(@funneled_on_title)
      orig_media_urls_sum = count_media_urls(@master_rss) + count_media_urls(@other_rss)

      media_urls_sum.should be == orig_media_urls_sum
    end

    it "should pull both urls into one item by title" do
      count_items(@funneled_on_title).should == 1
      count_media_urls(@funneled_on_title).should == 2
    end

    it "should pull both urls into one item by description" do
      count_items(@funneled_on_description).should == 1
      count_media_urls(@funneled_on_description).should == 2
    end
  end
end

describe "With longer moremi feeds" do
  before do
    @master_rss = File.read("spec/rss/moremi_podcast_720_longer.rss")
    @other_rss  = File.read("spec/rss/moremi_podcast_ipod_longer.rss")
    @master_feed = FeedFunnel::Feed.new(@master_rss)
    @other_feed  = FeedFunnel::Feed.new(@other_rss)
  end

  describe FeedFunnel::Funnel do
    before do
      @funneled_on_description = FeedFunnel::Funnel.new(@master_feed,
                                                        :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| strip_html((i.h % :description).inner_text) }],
                                                        :feeds    => [@other_feed])
      @funneled_on_description = @funneled_on_description.GO!.to_s

      @funneled_on_title = FeedFunnel::Funnel.new(@master_feed,
                                                        :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
                                                        :feeds    => [@other_feed])
      @funneled_on_title = @funneled_on_title.GO!.to_s

      @h_on_description = Hpricot::XML(@funneled_on_description)
      @h_on_title = Hpricot::XML(@funneled_on_title)
    end

    it "shouldn't lose any media urls" do
      media_urls_sum      = count_media_urls(@funneled_on_title)
      orig_media_urls_sum = count_media_urls(@master_rss) + count_media_urls(@other_rss)

      media_urls_sum.should == orig_media_urls_sum
    end

    it "should pull both urls into one item by title" do
      count_items(@funneled_on_title).should == 4
      count_media_urls(@funneled_on_title).should == 6

      count_media_urls_in((@h_on_title / :item)[0]).should == 2
      count_media_urls_in((@h_on_title / :item)[1]).should == 2
      count_media_urls_in((@h_on_title / :item)[2]).should == 1
      count_media_urls_in((@h_on_title / :item)[3]).should == 1
    end

    it "should pull both urls into one item by description" do
      count_items(@funneled_on_description).should == 4
      count_media_urls(@funneled_on_description).should == 6

      count_media_urls_in((@h_on_description / :item)[0]).should == 2
      count_media_urls_in((@h_on_description / :item)[1]).should == 2
      count_media_urls_in((@h_on_description / :item)[2]).should == 1
      count_media_urls_in((@h_on_description / :item)[3]).should == 1
    end
  end
end

describe "With rev3 feeds" do
  before do
    @master_rss = File.read("spec/rss/rev3_coop_mp4.rss")
    @other_rss  = File.read("spec/rss/rev3_coop_flash_large.rss")
    @master_feed = FeedFunnel::Feed.new(@master_rss)
    @other_feed  = FeedFunnel::Feed.new(@other_rss)
  end

  describe FeedFunnel::Funnel do
    before do
      @funneled_on_description = FeedFunnel::Funnel.new(@master_feed,
                                                        :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| strip_html((i.h % :description).inner_text) }],
                                                        :feeds    => [@other_feed]).GO!.to_s
      @funneled_on_title = FeedFunnel::Funnel.new(@master_feed,
                                                        :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
                                                        :feeds    => [@other_feed]).GO!.to_s
    end

    it "shouldn't lose any media urls" do
      media_urls_sum      = count_media_urls(@funneled_on_title)
      orig_media_urls_sum = count_media_urls(@master_rss) + count_media_urls(@other_rss)

      media_urls_sum.should be == orig_media_urls_sum
    end

    it "should be able match items up by description" do
      count_items(@funneled_on_description).should == count_items(@master_rss)
    end
  end
end

describe "With single buggy moremi episode" do
  before do
    @master_rss = File.read("spec/rss/moremi_podcast_720_single_buggy_episode.rss")
    @other_rss  = File.read("spec/rss/moremi_podcast_ipod_single_buggy_episode.rss")
    @master_feed = FeedFunnel::Feed.new(@master_rss)
    @other_feed  = FeedFunnel::Feed.new(@other_rss)
  end

  describe FeedFunnel::Funnel do
    describe "with title" do
      before do
        @funneled_on_title = FeedFunnel::Funnel.new(@master_feed,
                                                          :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
                                                          :feeds    => [@other_feed]).GO!.to_s
        @h_on_title = Hpricot::XML(@funneled_on_title)

      end

      it "shouldn't lose any media urls" do
        media_urls_sum      = count_media_urls(@funneled_on_title)
        orig_media_urls_sum = count_media_urls(@master_rss) + count_media_urls(@other_rss)

        media_urls_sum.should == orig_media_urls_sum
      end

      it "should have 1 episode with 2 media urls" do
        count_items(@funneled_on_title).should == 1
        count_media_urls(@funneled_on_title).should == 2
      end
    end

    describe "with description" do
      before do
        @funneled_on_description = FeedFunnel::Funnel.new(@master_feed,
                                                          :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| strip_html((i.h % :description).inner_text) }],
                                                          :feeds    => [@other_feed]).GO!.to_s
        @h_on_description = Hpricot::XML(@funneled_on_description)
      end

      it "should have 1 episode with 2 media urls" do
        count_items(@funneled_on_description).should == 1
        count_media_urls(@funneled_on_description).should == 2
      end
    end
  end
end

describe "With full moremi feeds" do
  before do
    @master_rss = File.read("spec/rss/moremi_podcast_720.rss")
    @other_rss  = File.read("spec/rss/moremi_podcast_ipod.rss")
    @master_feed = FeedFunnel::Feed.new(@master_rss)
    @other_feed  = FeedFunnel::Feed.new(@other_rss)
  end

  describe FeedFunnel::Funnel do
    describe "with title" do
      before do
        @funneled_on_title = FeedFunnel::Funnel.new(@master_feed,
                                                          :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
                                                          :feeds    => [@other_feed]).GO!.to_s
        @h_on_title = Hpricot::XML(@funneled_on_title)
      end

      it "shouldn't lose any media urls" do
        media_urls_sum      = count_media_urls(@funneled_on_title)
        orig_media_urls_sum = count_media_urls(@master_rss) + count_media_urls(@other_rss)

        media_urls_sum.should == orig_media_urls_sum
      end

      it "should pull both urls into one item by title" do
        (@h_on_title / :item).each do |i|
          count_media_urls_in(i).should == 2
        end
      end
    end

    describe "with description" do
      before do
        @funneled_on_description = FeedFunnel::Funnel.new(@master_feed,
                                                          :matchers => [FeedFunnel::LevenshteinMatcher.new {|i| strip_html((i.h % :description).inner_text) }],
                                                          :feeds    => [@other_feed]).GO!.to_s
        @h_on_description = Hpricot::XML(@funneled_on_description)
      end

      it "should pull both urls into one item by description" do
        (@h_on_description / :item).each do |i|
          count_media_urls_in(i).should == 2
        end
      end
    end
  end
end

describe "Manipulating the funneled feed" do
  before do
    @simple_funnel = FeedFunnel::Funnel.new(
      FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss")),
      :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :enclosure)[:url] }],
      :feeds => [FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))],
      :title => "my funneled feed")
    @coop_funnel = FeedFunnel::Funnel.new(
      FeedFunnel::Feed.new(File.read("spec/rss/rev3_coop_mp4.rss")),
      :matchers => [FeedFunnel::DirectMatcher.new {|i| (i.h % :title).inner_text }],
      :feeds    => [FeedFunnel::Feed.new(File.read("spec/rss/rev3_coop_flash_large.rss"))],
      :title => "CO-OP")
  end
  
  it "should mixin the title when it doesn't exist" do
    @simple_funnel.GO!.to_s.should match(/<title>my funneled feed<\/title>/)
  end

  it "should mixin the title when it already exists" do
    @coop_funnel.GO!.to_s.should match(/<title>CO-OP<\/title>/)
  end
  
  it "should include the feedfunnel namespace" do
    @simple_funnel.GO!.to_s.should match(/<rss [^>]*xmlns:combinificator="http:\/\/combinificator.com\/rss"/)
  end

  it "should not include the feedfunnel'ed namespaced links if they don't exist" do
    @simple_funnel.GO!.to_s.should match(/<combinificator:group><\/combinificator:group>/)
  end

  it "should include the feedfunnel'ed original links with sample extension, size & duration if they exist" do
    feed = @coop_funnel.GO!.to_s
    expected  = %Q!<combinificator:group>!
    expected += %Q!<combinificator:source size="269770468" isPrimary="false" url="http://revision3.com/coop/feed/flash-large/" type="video/x-flv" duration="1744"></combinificator:source>!
    expected += %Q!<combinificator:source size="578074253" isPrimary="true" url="http://revision3.com/coop/feed/mp4-hd30/" type="video/mp4" duration="1744"></combinificator:source>!
    expected += %Q!</combinificator:group>!
    feed.should match(Regexp.new(expected))
  end
end

