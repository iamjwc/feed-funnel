class FeedFunnel::Funnel
  def initialize(feed, &b)
    @master_feed = feed
    @b = b
  end

  def field_from(item)
    @b.call(item)
  end

  def funnel(feed)
    @master_feed.items.each do |item|
      feed.items.each do |f_item|
        item.media += f_item.enclosure_values if self.similar?(item, f_item)
      end
    end

    @master_feed
  end
end

