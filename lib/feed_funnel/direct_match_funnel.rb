
module FeedFunnel
  class DirectMatchFunnel < Funnel
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
      self.field_from(item) == self.field_from(f_item)
    end
  end
end

