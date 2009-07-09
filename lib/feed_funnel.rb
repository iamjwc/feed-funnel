module FeedFunnel; end

$: << File.join(File.dirname(__FILE__), "core_ext")
require 'array'
require 'date_time'

$: << File.join(File.dirname(__FILE__), "feed_funnel")
require 'feed'
require 'funnel'
require 'levenshtein_funnel'
require 'direct_match_funnel'
require 'date_proximity_funnel'

# # Use publish date to determine if episodes are close at all.
# M = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_1.rss"))
# c = FeedFunnel::LevenshteinFunnel.new(M) {|i| (i.h % :description).inner_text.gsub(/<[^>]*>/, "").gsub!(/\W+/, " ") }
# 
# F = FeedFunnel::Feed.new(File.read("spec/rss/super_simple_2.rss"))
# D = c.funnel(F)

