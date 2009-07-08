
module FeedFunnel
  class Funnel
    def initialize(feed, &b)
      @master_feed = feed
      @b = b
    end

    def field_from(item)
      @b.call(item)
    end
  end
end

