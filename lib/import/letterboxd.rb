require 'nokogiri'
require 'httparty'
require 'active_support/all'

 module Import
   class Letterboxd
    def initialize(rss_feed_url:, count:)
      @feed = rss_feed_url
      @count = count
    end

    def recent_movies
      response = HTTParty.get(@feed)
      return nil if response.code >= 400
      xml = Nokogiri::XML(response.body)
      movies = xml.css('item').sort { |a,b|  Time.parse(b.css('letterboxd|watchedDate').text) <=> Time.parse(a.css('letterboxd|watchedDate').text) }.map { |item| movie(item)}.slice(0, @count)
      File.open('data/movies.json','w'){ |f| f << movies.to_json }
     end

    def movie(item)
      {
        id: item.css('guid').text,
        title: item.css('letterboxd|filmTitle').text,
        year: item.css('letterboxd|filmYear').text,
        rewatch: item.css('letterboxd|rewatch').text.downcase == 'yes',
        watched_date: Time.parse(item.css('letterboxd|watchedDate').text),
        image_url: poster_image(item.css('description').text),
        url: item.css('link').text
      }.compact
    end

    def poster_image(description)
      html = Nokogiri::HTML(description)
      html.at_css('img')['src']
    end
  end
end
