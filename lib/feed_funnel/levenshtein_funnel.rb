require 'levenshtein'

module FeedFunnel
  class LevenshteinFunnel < Funnel
    def funnel(feed)
      items, distances = {}, {}

      @master_feed.items.each do |item|
        lowest_edit_distance = most_similar_item_to(item, feed)

        if lowest_edit_distance
          items[item]     = lowest_edit_distance.first
          distances[item] = lowest_edit_distance.last
        end
      end

      compute_stats(distances)

      @master_feed.items.each do |item|
        if relevant?(distances[item])
          item.media += items[item].enclosure_values
        end
      end

      @master_feed
    end

    protected

    def most_similar_item_to(item, feed)
      str = self.field_from(item)

      edit_distances = []
      feed.items.each do |other_item|
        other_str = self.field_from(other_item)

        next if (str.size - other_str.size).abs > 20

        distance = Levenshtein::distance(str, other_str)
        edit_distances << [other_item, distance]

        break if distance == 0
      end
      edit_distances.sort_by {|a| a.last }.first
    end

    def compute_stats(distances)
      @mean    = distances.values.mean
      @std_dev = distances.values.standard_deviation
    end

    def relevant?(distance)
      distance - (@mean + @std_dev) <= 0
    end
  end
end

