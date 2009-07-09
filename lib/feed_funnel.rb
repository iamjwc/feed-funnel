require 'hpricot'

module FeedFunnel; end

$: << File.join(File.dirname(__FILE__), "feed_funnel")
require 'feed'
require 'funnel'
require 'levenshtein_funnel'
require 'direct_match_funnel'

class Array
  def mean
    self.inject(0) {|n, i| n + i } / self.size.to_f
  end

  def standard_deviation(mean = nil)
    mean ||= self.mean

    Math.sqrt(self.map {|i| (i - mean) ** 2 }.mean)
  end
end

# # Use publish date to determine if episodes are close at all.
# M = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
# c = FeedFunnel::LevenshteinFunnel.new(M) {|i| (i.h % :description).inner_text.gsub(/<[^>]*>/, "").gsub!(/\W+/, " ") }
# 
# F = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))
# D = c.funnel(F)

