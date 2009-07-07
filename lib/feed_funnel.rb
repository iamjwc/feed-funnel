$: << File.join(File.dirname(__FILE__), "feed_funnel")
require 'levenshtein'

require 'feedzirra'
require 'haml'

class Array
  def mean
    self.inject(0) {|n, i| n + i } / self.size.to_f
  end

  def standard_deviation(mean = nil)
    mean ||= self.mean

    Math.sqrt(self.map {|i| (i - mean) ** 2 }.mean)
  end
end

module FeedFunnel
  class Funnel
    def initialize(master_feed)
      @master_feed = master_feed

      @master_entries = {}
      @master_feed.entries.each {|e| @master_entries[e] = [] }
    end
  end
 
  class LevenshteinFunnel < Funnel
    def funnel(feed, &b)
      entries   = {}
      distances = {}

      @master_feed.entries.each do |entry|
        lowest_edit_distance = most_similar_entry_to(entry, feed, &b)

        if lowest_edit_distance
          entries[entry]   = lowest_edit_distance.first
          distances[entry] = lowest_edit_distance.last
        end
      end

      compute_stats(distances)

      @master_feed.entries.each do |entry|
        @master_entries[entry] << entries[entry] if relevant?(distances[entry])
      end

      @master_entries
    end

    private

    def most_similar_entry_to(entry, feed, &b)
      str = b.call(entry)

      edit_distances = []
      feed.entries.each do |other_entry|
        other_str = b.call(other_entry)

        next if (str.size - other_str.size).abs > 20

        distance = Levenshtein::distance(str, other_str)
        edit_distances << [other_entry, distance]

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

  class DirectMatchFunnel < Funnel
    def funnel(feed, &b)
    end
  end

  class Merger
    def initialize
    end
  end
end

c = FeedFunnel::LevenshteinFunnel.new(Feedzirra::Feed.parse(File.read("spec/rss/alaska_hdtv.rss")))
feed = Feedzirra::Feed.parse(File.read("spec/rss/alaska_podshow.rss"))
#p c.funnel {|e| e.title }
D = c.funnel(feed) {|e| e.summary.gsub(/<[^>]*>/, "").gsub!(/\W+/, " ") }

