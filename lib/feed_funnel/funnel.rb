class FeedFunnel::Funnel
  def initialize(feed, &b)
    @master_feed = feed
    @b = b
  end

  def field_from(item)
    @b.call(item)
  end

  def funnel(feed)
    all_feed_items = feed.items.dup

    @master_feed.items.each do |item|
      all_feed_items.each do |f_item|
        if self.similar?(item, f_item)
          item.add_media(f_item.enclosure_values)

          # Get rid of items that have been associated with the master feed
          all_feed_items.delete(f_item)
        end
      end
    end
    all_feed_items.each {|i| @master_feed.items << i }

    @master_feed
  end
end

