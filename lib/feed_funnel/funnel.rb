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
        if self.similar?(item, f_item)
          item.add_media(f_item.enclosure_values)
        else
          @master_feed.items << f_item
        end
      end
    end

    @master_feed
  end
end

