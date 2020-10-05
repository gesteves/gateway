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
      @amazon = Vacuum.new(marketplace: ENV['AMAZON_MARKETPLACE'], access_key: ENV['AMAZON_ASSOCIATES_ACCESS_KEY'], secret_key: ENV['AMAZON_ASSOCIATES_SECRET_KEY'], partner_tag: ENV['AMAZON_ASSOCIATES_TAG'])
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
      %w{ nature other street how-to }.each do |shelf|
        shelf = "photography-#{shelf}"
        puts "  Importing shelf: #{shelf}"
        book_ids = book_ids_in_shelf(name: shelf)
        books = book_ids.map { |id| book(id: id) }.compact
        File.open("data/#{shelf.gsub('-', '_')}_books.json",'w'){ |f| f << books.sort { |a,b| a[:title] <=> b[:title] }.to_json }
      end
    end

    def book_ids_in_shelf(name:, per_page: nil)
      rss_feed = @feed + "&shelf=#{name}"
      rss_feed += "&per_page=#{per_page}" if per_page.present?
      xml = Nokogiri::XML(HTTParty.get(rss_feed).body)
      xml.css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text) }.map { |item| item.css('book_id').first.content }
    end

    def book(id:)
      redis_key = "goodreads:book:data:#{id}"
      data = @redis.get(redis_key)
      return JSON.parse(data).with_indifferent_access if data.present?

      book = get_book_api_data(id: id)
      return nil if book.blank?

      id = book.css('id').first.content
      goodreads_url = book.css('url').first.content
      image_url = book_cover_url(goodreads_url)
      amazon_url = amazon_url(book: book)
      return nil if image_url.blank? || image_url.match?(/\/nophoto\//)

      data = {
        id: id,
        title: book.css('title').first.content,
        authors: book.css('authors').first.css('author name').map(&:content),
        image_url: image_url,
        goodreads_url: goodreads_url,
        amazon_url: amazon_url,
        published: publication_year(book: book),
        description: book.css('description').first.content,
        description_plain: Sanitize.fragment(book.css('description').first.content).gsub(/\s+/, ' ').strip
      }.compact

      @redis.setex(redis_key, 1.day.to_i, data.to_json)
      data
    end

    def get_book_api_data(id:)
      redis_key = "goodreads:book:api:#{id}"
      data = @redis.get(redis_key)
      if data.blank?
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
        response = HTTParty.get(goodreads_url)
        return nil unless response.code == 200
        markup = Nokogiri::HTML(response.body)
        cover_image = markup.at_css('#coverImage')
        return nil unless cover_image.present?
        url = markup.at_css('#coverImage')['src']
        ttl = 1.day.to_i + rand(90).day.to_i
        @redis.setex(redis_key, ttl, url)
      end
      url
    end

    def amazon_url(book:)
      asin = book.css('asin').first.content.presence || book.css('kindle_asin').first.content.presence
      isbn = book.css('isbn').first.content.presence || book.css('isbn13').first.content.presence
      return nil if (asin.blank? && isbn.blank?) || ENV['AMAZON_ASSOCIATES_TAG'].blank?
      return search_amazon_by_asin(asin) if asin.present?
      return search_amazon_by_isbn(isbn) if isbn.present?
    end

    def publication_year(book:)
      book.css('publication_year').first.content.presence || book.css('work original_publication_year').first.content.presence
    end

    def search_amazon_by_asin(asin)
      redis_key = "amazon:url:asin:#{asin}"
      url = @redis.get(redis_key)
      if url.blank?
        sleep 1
        response = @amazon.get_items(item_ids: [asin])
        if response.status == 200
          items = response.to_h.dig('ItemsResult', 'Items')
          url = items&.dig(0, 'DetailPageURL')
          puts "  Found results for ASIN #{asin}: #{url}" if url.present?
          @redis.setex(redis_key, 1.year.to_i, url) if url.present?
        end
      end
      url || "https://www.amazon.com/dp/#{asin}/?tag=#{ENV['AMAZON_ASSOCIATES_TAG']}"
    end

    def search_amazon_by_isbn(isbn)
      redis_key = "amazon:url:isbn:#{isbn}"
      url = @redis.get(redis_key)
      if url.blank?
        sleep 1
        response = @amazon.search_items(keywords: isbn)
        if response.status == 200
          items = response.to_h.dig('SearchResult', 'Items')
          url = items&.dig(0, 'DetailPageURL')
          puts "  Found results for ISBN #{isbn}: #{url}" if url.present?
          @redis.setex(redis_key, 1.year.to_i, url) if url.present?
        end
      end
      url || "https://www.amazon.com/s?k=#{isbn}&tag=#{ENV['AMAZON_ASSOCIATES_TAG']}"
    end
  end
end
