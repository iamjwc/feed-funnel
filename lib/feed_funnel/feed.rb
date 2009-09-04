require 'hpricot'

class FeedFunnel::Feed
  attr_reader :h, :items

  def initialize(rss)
    self.parse(rss)
  end

  def parse(rss)
    @h = Hpricot::XML(rss)
    @items = (h / :item).map {|i| Item.new(i) }
  end
  
  def add_title(new_title)
    self.h.search("channel/title").remove
    self.h.insert_before(Hpricot.build { tag!("title", new_title) }.children, h.at('item'))
  end

  def add_funnel_namespace
    self.h.at('rss').set_attribute 'xmlns:feedfunnel', "http://limecast.com/feedfunnelrss"
  end

  def add_funnel_origlinks(feeds)
    # Ex: <atom:link rel="self" href="http://revision3.com/coop/feed/flash-large/" />
    # Ex: <atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" href="http://feeds.feedburner.com/alaskahdtv" type="application/rss+xml" />
    (feeds << self).each do |feed|
      if link = feed.h.at('atom:link[@rel=self]') || feed.h.at('atom10:link[@rel=self]')
        self.h.at('channel').children << Hpricot.build { tag!("feedfunnel:origLink", link['href']) }
      end
    end
  end

  def to_s
    channel = (self.h % :channel)
    channel.children.each_with_index do |e,i|
      if e.class == Hpricot::Elem && e.name == "item"
        channel.children[i] = Hpricot::XML("")
      end
    end

    @items.each do |item|
      channel.children << item.to_h
    end

    self.h.to_s
  end

end

class FeedFunnel::Feed::Item
  attr_reader :h

  def initialize(h)
    @h = h
    @media = []
    @media_by_url = {}

    self.parse_media
  end

  def enclosure_values
    ((h / :enclosure) + (h / :"media:content")).map do |media|
      {
        :url  => media[:url],
        :size => media[:length] || media[:fileSize],
        :type => media[:type]
      }
    end
  end

  def add_media(media)
    [*media].each do |m|
      @media_by_url[m[:url]] ||= {:count => 0, :media => m}
      @media_by_url[m[:url]][:count] += 1
      @media << m
    end
  end

  def parse_media
    self.add_media(self.enclosure_values)
  end

  def to_h
    self.remove_enclosures
    self.add_media_group
    self.h
  end

  protected

  def remove_enclosures
    idxs = []
    h.children.each_with_index do |e, i|
      if e.class == Hpricot::Elem && e.name =~ /media:content|media:group|enclosure/
        h.children[i] = Hpricot::XML("")
      end
    end
  end

  def add_media_group
    group = (Hpricot::XML("<media:group />") % :"media:group")
    @media_by_url.each do |k, m|
      group.children << media_tag(:"media:content", m[:media])
    end
    h.children << media_tag(:enclosure, @media.first)
    h.children << group
  end

  def media_tag(name, m)
    el = (Hpricot::XML("<#{name} />") % name)
    el[:url]  = m[:url]
    el[:type] = m[:type]
    el[(name.to_s =~ /enclosure/) ? :length : :fileSize] = m[:size]

    el
  end
end

