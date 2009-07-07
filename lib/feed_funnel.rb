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

# Use publish date to determine if episodes are close at all.

Feedzirra::Feed.add_common_feed_entry_element(:enclosure, :value => :url)
Feedzirra::Feed.add_common_feed_entry_element(:enclosure, :value => :length, :as => :enclosure_size)

Feedzirra::Feed.add_common_feed_entry_element(:"media:content", :value => :url, :as => :media_url)
Feedzirra::Feed.add_common_feed_entry_element(:"media:content", :value => :fileSize, :as => :media_size)

module Feedzirra
  module Parser
    class MediaGroupEntry
      include SAXMachine
      include FeedUtilities

      elements :"media:content", :value => :url, :as => :media_urls
      elements :"media:content", :value => :fileSize, :as => :media_sizes

      def self.able_to_parse?(xml)
        xml =~ /media:group/
      end
    end
  end
end
Feedzirra::Feed.add_common_feed_entry_element(:"media:group", :class => Feedzirra::Parser::MediaGroupEntry)

module FeedFunnel
  class Funnel
    def initialize(rss, &b)
      @master_feed = self.parse(rss)

      @sources = {}
      @master_feed.entries.each {|e| @sources[e] = [] }

      @b = b
    end

    def merge
    end

    protected

    def split_items(rss)
      r = rss.dup
    
      acc = {:before => "", :after => "", :items => []}
    
      # Get xml up to the first enclosure
      b = (r =~ /<item/)
      acc[:before] = r[0..b]
      r[b..r.size]
    
      while a = (r =~ /<item/)
        b = (r[a..r.size] =~ /<\/item>/) + 7 # + 2 for the length of the end tag
    
        acc[:items] << r[a..a+b-1]
        r = r[a+b..r.size]
      end
    
      acc[:after] = r
    
      acc
    end

    def parse(feed)
      Feedzirra::Feed.parse(feed)
    end

    def add_source(master_entry, source)
      @master_entries[master_entry] += [*source]
    end

    def field_from(feed)
      @b.call(feed)
    end

    def enclosure_values(entry)
      {
        :url    => entry.encloure_url     || entry.media_url,
        :length => entry.enclosure_length || entry.media_length,
        :type   => entry.enclosure_type   || entry.media_type
      }
    end
  end
 
  class LevenshteinFunnel < Funnel
    def funnel(feed)
      entries   = {}
      distances = {}

      @master_feed.entries.each do |entry|
        lowest_edit_distance = most_similar_entry_to(entry, feed)

        if lowest_edit_distance
          entries[entry]   = lowest_edit_distance.first
          distances[entry] = lowest_edit_distance.last
        end
      end

      compute_stats(distances)

      @master_feed.entries.each do |entry|
        if relevant?(distances[entry])
          self.link_episodes(entry, self.enclosure_values(entries[entry]))
        end
      end
    end

    protected

    def most_similar_entry_to(entry, feed)
      str = self.field_from(entry)

      edit_distances = []
      feed.entries.each do |other_entry|
        other_str = self.field_from(other_entry)

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
    def funnel(feed)
      @master_feed.entries.each do |entry|
        feed.entries.each do |f_entry|
          if self.field_from(entry) == self.field_from(f_entry)
            self.link_episodes(entry, self.enclosure_values(entries[entry]))
          end
        end
      end
    end
  end
end

c = FeedFunnel::LevenshteinFunnel.new(Feedzirra::Feed.parse(File.read("spec/rss/alaska_hdtv.rss"))) {|e| e.summary.gsub(/<[^>]*>/, "").gsub!(/\W+/, " ") }
feed = Feedzirra::Feed.parse(File.read("spec/rss/alaska_podshow.rss"))
#p c.funnel {|e| e.title }
#D = c.funnel(feed)

