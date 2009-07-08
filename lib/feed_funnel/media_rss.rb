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

    class MediaRSS
      include SAXMachine
      include FeedUtilities
 
      element :enclosure, :value => :url
      element :enclosure, :value => :length, :as => :enclosure_size

      element :"media:content", :value => :url, :as => :media_url
      element :"media:content", :value => :fileSize, :as => :media_size

      element :"media:group", :class => MediaGroupEntry


      element :copyright
      element :description
      element :language
      element :managingEditor
      element :title
      element :link, :as => :url

      elements :item, :as => :entries, :class => ITunesRSSItem

      def self.able_to_parse?(xml)
        xml =~ /enclosure/ || xml =~ /media:content/
      end
    end
  end
end

Feedzirra::Feed.add_feed_class(Feedzirra::Parser::MediaRSS)
