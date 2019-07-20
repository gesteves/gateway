require 'nokogiri'
require 'httparty'
require 'redis'
require 'active_support/all'

module Import
  class Goodreads
    def initialize(rss_feed_url:)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      @feed = rss_feed_url
    end

    def recent_books(count:)
      books = []
      ['currently-reading', 'read'].each do |shelf|
        books << shelf(name: shelf)
      end
      books = books.flatten.slice(0, count)
      books = books.map { |b| add_amazon_url(book: b) }.reject { |b| b[:amazon_url].nil? }
      books.map { |b| save_image(book: b) }
      File.open('data/books.json','w'){ |f| f << books.to_json }
    end

    def shelf(name:)
      rss_feed = @feed + "&shelf=#{name}"
      books = []
      Nokogiri::XML(HTTParty.get(rss_feed).body).css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text)}.each do |item|
        book = {
          id: item.css('book_id').first.content,
          title: item.css('title').first.content,
          author: item.css('author_name').first.content,
          image_url: item.css('book_large_image_url').first.content,
          goodreads_url: Nokogiri.HTML(item.css('description').first.content).css('a').first['href'].gsub('?utm_medium=api&utm_source=rss', ''),
          published: item.css('book_published').first.content,
          shelf: name
        }
        books << book
      end
      books
    end

    def add_amazon_url(book:)
      asin = asin(url: book[:goodreads_url])
      book[:amazon_url] = if asin.present?
        asin.match?(/^\d{10,13}$/) ? "https://www.amazon.com/s?k=#{asin}&tag=#{ENV['AMAZON_ASSOCIATES_TAG']}" : "https://www.amazon.com/gp/product/#{asin}/?tag=#{ENV['AMAZON_ASSOCIATES_TAG']}"
      else
        nil
      end
      book
    end

    def asin(url:)
      asin = @redis.get("goodreads:asin:#{url}")
      if asin.nil?
        markup = Nokogiri.HTML(HTTParty.get(url).body)
        asin = markup.css('[itemprop=isbn]')&.first&.content
        @redis.setex("goodreads:asin:#{url}", 1.week.seconds.to_i, asin) unless asin.nil?
      end
      asin
    end

    def save_image(book:)
      File.open("source/images/books/#{book[:id]}.jpg",'w'){ |f| f << HTTParty.get(book[:image_url]).body }
    end
  end
end
