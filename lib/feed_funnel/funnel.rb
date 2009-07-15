class FeedFunnel::Funnel
  attr_reader :matchers, :feeds

  def initialize(master_feed, opts = {})
    @master_feed = master_feed
    @matchers = opts[:matchers] || []
    @feeds = opts[:feeds] || []
  end

  def GO!
    self.preprocess
    similar_items  = self.similar_items
    all_feed_items = self.all_feed_items

    @master_feed.items.each do |item|
      similar_items.keys.each do |similar_item|
        item.add_media(similar_item.enclosure_values) if all_feed_items.include?(similar_item)

        # Get rid of items that have been associated with the master feed
        all_feed_items.delete(similar_item)
      end
    end
    all_feed_items.each {|item| @master_feed.items << item }

    @master_feed
  end

  protected

  def all_feed_items
    @feeds.map {|feed| feed.items.dup }.flatten
  end

  def similar_items
    similar_items = {}
    @feeds.each do |feed|
      @matchers.each do |matcher|
        @master_feed.items.each do |item|
          items = matcher.similar_items(item, feed.items)
          items.each do |i|
            (similar_items[i] ||= []) << matcher
          end
        end
      end
    end
    similar_items
  end

  def preprocess
    @feeds.each do |feed|
      @matchers.each do |matcher|
        matcher.preprocess(@master_feed, feed) if matcher.respond_to? :preprocess
      end
    end
  end
end

