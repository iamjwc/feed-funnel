require 'levenshtein'

class FeedFunnel::LevenshteinMatcher < FeedFunnel::Matcher
  def similar_items(item, other_items)
    @items[item] && relevant?(@distances[item]) ? [@items[item]] : []
  end

  def preprocess(master_feed, feed)
    @items, @distances = {}, {}

    master_feed.items.each do |item|
      lowest_edit_distance = most_similar_item_to(item, feed)

      if lowest_edit_distance
        @items[item]     = lowest_edit_distance[:item]
        @distances[item] = lowest_edit_distance[:distance]
      end
    end

    compute_stats
  end

  protected

  def most_similar_item_to(item, feed)
    str = self.field_from(item)

    edit_distances = []
    feed.items.each do |other_item|
      other_str = self.field_from(other_item)

      # If one of the strings is much longer than the other,
      # don't even bother compute edit distance
      next if (str.size - other_str.size).abs > 20

      distance = Levenshtein::distance(str, other_str)
      edit_distances << {:item => other_item, :distance => distance}

      # Quit early if we get an exact match
      break if distance == 0
    end
    edit_distances.sort_by {|h| h[:distance] }.first
  end

  def compute_stats
    @mean    = @distances.values.mean
    @std_dev = @distances.values.standard_deviation
  end

  def relevant?(distance)
    distance - (@mean + @std_dev) <= 0
  end
end

