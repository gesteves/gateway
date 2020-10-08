require 'nokogiri'
require 'httparty'
require 'sanitize'
require 'redis'
require 'vacuum'
require 'active_support/all'

module Import
  class Goodreads
    def initialize(api_key:, rss_feed_url:)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      @associates_tag = ENV['AMAZON_ASSOCIATES_TAG']
      @bookshop_id = ENV['BOOKSHOP_AFFILIATE_ID']
      @amazon = Vacuum.new(marketplace: ENV['AMAZON_MARKETPLACE'], access_key: ENV['AMAZON_ASSOCIATES_ACCESS_KEY'], secret_key: ENV['AMAZON_ASSOCIATES_SECRET_KEY'], partner_tag: @associates_tag)
      @feed = rss_feed_url
      @key = api_key
    end

    def recent_books
      book_ids = []
      %w{ currently-reading read }.each do |shelf|
        puts "  Importing shelf: #{shelf}"
        book_ids += book_ids_in_shelf(name: shelf, per_page: ENV['GOODREADS_COUNT'])
      end
      books = book_ids.map { |id| book(id: id) }.compact
      File.open('data/books.json','w'){ |f| f << books.to_json }
    end

    def photography_books
      %w{ nature street music travel how-to other }.each do |shelf|
        shelf = "photography-#{shelf}"
        puts "  Importing shelf: #{shelf}"
        book_ids = book_ids_in_shelf(name: shelf)
        books = book_ids.map { |id| book(id: id) }.compact
        File.open("data/#{shelf.gsub('-', '_')}_books.json",'w'){ |f| f << books.sort_by { |b| b[:authors].join(' ') }.to_json }
      end
    end

    def book_ids_in_shelf(name:, per_page: nil)
      rss_feed = @feed + "&shelf=#{name}"
      rss_feed += "&per_page=#{per_page}" if per_page.present?
      xml = Nokogiri::XML(HTTParty.get(rss_feed).body)
      xml.css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text) }.map { |item| item.css('book_id').first.content }
    end

    def book(id:)
      book = get_book_api_data(id: id)
      return nil if book.blank?

      id = book.css('id').first.content
      goodreads_url = book.css('url').first.content
      image_url = book_cover_url(goodreads_url)
      isbn = isbn(book: book)
      isbn13 = isbn13(book: book)
      amazon_url = amazon_url(isbn: isbn13) || amazon_url(isbn: isbn)
      bookshop_url = bookshop_url(isbn: isbn13)

      {
        id: id,
        title: book.css('title').first.content,
        authors: book.css('authors').first.css('author name').map(&:content),
        image_url: image_url,
        goodreads_url: goodreads_url,
        amazon_url: amazon_url,
        bookshop_url: bookshop_url,
        isbn: isbn,
        isbn13: isbn13,
        published: publication_year(book: book),
        description: book.css('description').first.content,
        description_plain: Sanitize.fragment(book.css('description').first.content).gsub(/\s+/, ' ').strip
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

    def amazon_url(isbn:)
      return nil if isbn.blank? || @associates_tag.blank?
      redis_key = "amazon:#{@associates_tag}:url:isbn:#{isbn}"
      url = @redis.get(redis_key)
      if url.blank?
        puts "    Searching Amazon for ISBN #{isbn}"
        response = @amazon.search_items(keywords: isbn)
        if response.status == 200
          url = response.to_h.dig('SearchResult', 'Items', 0, 'DetailPageURL')
          if url.present?
            ttl = 1.year.to_i
            @redis.setex(redis_key, ttl, url)
          end
        end
        sleep 1
      end
      url || "https://www.amazon.com/s?k=#{isbn}&tag=#{@associates_tag}"
    end

    def bookshop_url(isbn:)
      return nil if isbn.blank? || @bookshop_id.blank?
      redis_key = "bookshop:#{@bookshop_id}:url:isbn:#{isbn}"
      url = @redis.get(redis_key)
      if url.blank?
        puts "    Searching Bookshop for ISBN #{isbn}"
        url = "https://bookshop.org/a/#{@bookshop_id}/#{isbn}"
        response = HTTParty.head(url)
        if response.code >= 400
          url = nil
        else
          ttl = 1.year.to_i
          @redis.setex(redis_key, ttl, url)
        end
      end
      url
    end

    def publication_year(book:)
      book.css('publication_year').first.content.presence || book.css('work original_publication_year').first.content.presence
    end
  end
end
