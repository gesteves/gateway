require 'nokogiri'
require 'httparty'
require 'sanitize'
require 'redis'
require 'active_support/all'

 module Import
  class Goodreads
    def initialize(api_key:, rss_feed_url:)
      uri = URI.parse(ENV['REDIS_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      @feed = rss_feed_url
      @key = api_key
    end

    def recent_books
      books = []
      %w{ currently-reading read }.each do |shelf|
        puts "  Importing shelf: #{shelf}"
        book_ids = book_ids_in_shelf(name: shelf, per_page: ENV['GOODREADS_COUNT'])
        books += book_ids.map { |id| book(id: id, shelf: shelf) }.compact
      end
      File.open('data/books.json','w'){ |f| f << books.to_json }
    end

    def book_ids_in_shelf(name:, per_page: nil)
      rss_feed = @feed + "&shelf=#{name}"
      rss_feed += "&per_page=#{per_page}" if per_page.present?
      response = HTTParty.get(rss_feed)
      return nil if response.code >= 400
      xml = Nokogiri::XML(response.body)
      xml.css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text) }.map { |item| item.css('book_id').first.content }
    end

    def book(id:, shelf:)
      book = get_book_api_data(id: id)
      return nil if book.blank?

      id = book.css('id').first.content
      goodreads_url = book.css('url').first.content
      image_url = book_cover_url(goodreads_url)
      isbn = isbn(book: book)
      isbn13 = isbn13(book: book)

      {
        id: id,
        title: book.css('title').first.content,
        authors: book.css('authors').first.css('author name').map(&:content),
        image_url: image_url,
        goodreads_url: goodreads_url,
        isbn: isbn,
        isbn13: isbn13,
        published: publication_year(book: book),
        description: book.css('description').first.content,
        description_plain: Sanitize.fragment(book.css('description').first.content).gsub(/\s+/, ' ').strip,
        shelf: shelf
      }.compact
    end

    def get_book_api_data(id:)
      redis_key = "goodreads:book:api:#{id}"
      data = @redis.get(redis_key)
      if data.blank?
        puts "    Requesting API data for book ID #{id}"
        response = HTTParty.get("https://www.goodreads.com/book/show/#{id}.xml?key=#{@key}")
        return nil unless response.code == 200
        data = response.body
        ttl = 1.day.to_i + rand(90).day.to_i
        @redis.setex(redis_key, ttl, data)
      end
      Nokogiri::XML(data).css('GoodreadsResponse book').first
    end

    def book_cover_url(goodreads_url)
      redis_key = "goodreads:book:cover:#{goodreads_url}"
      url = @redis.get(redis_key)
      if url.blank?
        puts "    Scraping book cover from: #{goodreads_url}"
        response = HTTParty.get(goodreads_url)
        return nil unless response.code == 200
        markup = Nokogiri::HTML(response.body)
        cover_image = markup.at_css('#coverImage')
        return nil unless cover_image.present?
        url = markup.at_css('#coverImage')['src']
        ttl = if url&.match?(/\/nophoto\//)
          1.week.to_i
        else
          1.year.to_i
        end
        @redis.setex(redis_key, ttl, url)
      end
      url
    end

    def isbn(book:)
      book.css('isbn').first.content.presence
    end

    def isbn13(book:)
      book.css('isbn13').first.content.presence
    end

    def publication_year(book:)
      book.css('publication_year').first.content.presence || book.css('work original_publication_year').first.content.presence
    end
  end
 end
