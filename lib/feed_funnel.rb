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

