class FeedFunnel::Matcher
  def initialize(&b)
    @b = b
  end

  def field_from(item)
    @b.call(item)
  end

  def funnel(master_feed, feed)
    other_items = feed.items.dup
    master_feed.items.each do |item|
      similar_items(item, other_items).each do |other_item|
        item.add_media(other_item.enclosure_values)

        # Get rid of items that have been associated with the master feed
        other_items.delete(other_item)
      end
    end
    other_items.each {|item| master_feed.items << item }

    master_feed
  end

  def similar_items(item, other_items)
    other_items.select {|other_item| self.similar?(item, other_item) }
  end

  def similar?(a,b)
    false
  end
end

