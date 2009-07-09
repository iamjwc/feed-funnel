
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
      master_date = DateTime.parse(self.field_from(item)).to_time
      other_date  = DateTime.parse(self.field_from(f_item)).to_time

      (master_date - other_date).abs <= 10 * 60
    end
  end
end

