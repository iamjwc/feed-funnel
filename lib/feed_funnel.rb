module FeedFunnel; end

$: << File.join(File.dirname(__FILE__), "core_ext")
require 'array'
require 'date_time'

$: << File.join(File.dirname(__FILE__), "feed_funnel")
require 'feed'
require 'matcher'
require 'funnel'
require 'levenshtein_matcher'
require 'direct_matcher'
require 'date_proximity_matcher'

