class FeedFunnel::Funnel
  attr_reader :matchers, :feeds

  def initialize(master_feed, opts = {})
    @master_feed = master_feed
    @matchers = opts[:matchers] || []
    @feeds = opts[:feeds] || []
  end

  def GO!
    @feeds.each do |feed|
      self.preprocess(feed)
      similar_items = self.similar_items(feed)
      other_items = feed.items.dup

      @master_feed.items.each do |item|
        similar_item = similar_items[item]
        item.add_media(similar_item.enclosure_values) if other_items.include?(similar_item)

      #debugger
        other_items.delete(similar_item)
      end
      other_items.each {|item| @master_feed.items << item }
    end

    @master_feed
  end

  protected

  def similar_items(feed)
    similar_items = {}
    @matchers.each do |matcher|
      @master_feed.items.each do |item|
        # Matcher gets all similar items between current master
        # feed item and all items in the other feed
        matcher.similar_items(item, feed.items).each do |matched_items|
          similar_items[item] = matched_items
        end
      end
    end
    similar_items
  end

  def preprocess(feed)
    @matchers.each do |matcher|
      matcher.preprocess(@master_feed, feed) if matcher.respond_to? :preprocess
    end
  end
end

