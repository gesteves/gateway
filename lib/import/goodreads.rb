require 'nokogiri'
require 'httparty'
require 'sanitize'
require 'redis'
require 'active_support/all'

module Import
  class Goodreads
    def initialize(api_key:, rss_feed_url:)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      @feed = rss_feed_url
      @key = api_key
    end

    def recent_books
      book_ids = []
      ['currently-reading', 'read'].each do |shelf|
        book_ids += book_ids_in_shelf(name: shelf)
      end
      books = book_ids.map { |id| book(id: id) }.compact
      File.open('data/books.json','w'){ |f| f << books.to_json }
    end

    def book_ids_in_shelf(name:)
      rss_feed = @feed + "&shelf=#{name}"
      xml = Nokogiri::XML(HTTParty.get(rss_feed).body)
      xml.css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text) }.map { |item| item.css('book_id').first.content }
    end

    def book(id:)
      data = @redis.get("goodreads:book:#{id}")
      api_url = "https://www.goodreads.com/book/show/#{id}.xml?key=#{@key}"
      if data.blank?
        response = HTTParty.get(api_url)
        return nil unless response.code == 200
        data = response.body
        @redis.setex("goodreads:book:#{id}", 1.month.seconds.to_i, data)
      end

      book = Nokogiri::XML(data).css('GoodreadsResponse book').first
      id = book.css('id').first.content
      goodreads_url = book.css('url').first.content
      image_url = book_cover_url(goodreads_url)
      amazon_url = amazon_url(book: book)
      return nil if image_url.blank? || image_url.match?(/\/nophoto\//)

      {
        id: id,
        title: book.css('title').first.content,
        authors: book.css('authors').first.css('author name').map(&:content),
        image_url: image_url,
        goodreads_url: goodreads_url,
        amazon_url: amazon_url,
        api_url: api_url,
        published: publication_year(book: book),
        description: book.css('description').first.content,
        description_plain: Sanitize.fragment(book.css('description').first.content).gsub(/\s+/, ' ').strip
      }.compact
    end

    def book_cover_url(goodreads_url)
      url = @redis.get("goodreads:book:cover:#{goodreads_url}")
      if url.blank?
        response = HTTParty.get(goodreads_url)
        return nil unless response.code == 200
        markup = Nokogiri::HTML(response.body)
        url = markup.at_css('#coverImage').dig('src')
        @redis.setex("goodreads:book:cover:#{goodreads_url}", 1.month.seconds.to_i, url) unless url.blank?
      end
      url
    end

    def amazon_url(book:)
      asin = book.css('asin').first.content.presence || book.css('kindle_asin').first.content.presence
      isbn = book.css('isbn').first.content.presence || book.css('isbn13').first.content.presence
      return nil if (asin.blank? && isbn.blank?) || ENV['AMAZON_ASSOCIATES_TAG'].blank?
      return "https://www.amazon.com/gp/product/#{asin}/?tag=#{ENV['AMAZON_ASSOCIATES_TAG']}" if asin.present?
      return "https://www.amazon.com/s?k=#{isbn}&tag=#{ENV['AMAZON_ASSOCIATES_TAG']}" if isbn.present?
    end

    def publication_year(book:)
      book.css('publication_year').first.content.presence || book.css('work original_publication_year').first.content.presence
    end
  end
end
