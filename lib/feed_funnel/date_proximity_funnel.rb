
# Use publish date to determine if episodes are close at all.
module FeedFunnel
  class DateProximityFunnel < Funnel
    def funnel(feed)
      @master_feed.items.each do |item|
        feed.items.each do |f_item|
          item.media += f_item.enclosure_values if self.relevant?(item, f_item)
        end
      end

      @master_feed
    end

    protected

    def relevant?(item, f_item)
      master_date = Date.parse(self.field_from(item))
      other_date  = Date.parse(self.field_from(f_item))

      master_date && other_date && (master_date > other_date - 1.day && master_date < other_date + 1.day)
    rescue
      false
    end
  end
end

