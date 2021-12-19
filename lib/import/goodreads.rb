require 'nokogiri'
require 'httparty'
require 'sanitize'
require 'active_support/all'

 module Import
  class Goodreads
    def initialize(rss_feed_url:, count:)
      @feed = rss_feed_url
      @count = count
    end

    def recent_books
      books = []
      %w{ currently-reading read }.each do |shelf|
        puts "  Importing shelf: #{shelf}"
        books += books_in_shelf(shelf: shelf)
      end
      books = books.slice(0, @count)
      File.open('data/books.json','w'){ |f| f << books.to_json }
    end

    def books_in_shelf(shelf:)
      rss_feed = @feed + "&shelf=#{shelf}"
      response = HTTParty.get(rss_feed)
      return if response.code >= 400
      xml = Nokogiri::XML(response.body)
      xml.css('item').map { |item| book(item: item, shelf: shelf) }.sort { |a,b| b[:date_added] <=> a[:date_added] }
    end

    def book(item:, shelf:)
      id = item.css('book_id').first.content

      {
        id: id,
        title: item.css('title').first.content,
        author: item.css('author_name').first.content,
        image_url: item.css('book_large_image_url').first.content,
        goodreads_url: "https://www.goodreads.com/book/show/#{id}",
        published: item.css('book_published').first.content,
        date_added: Time.parse(item.css('user_date_created').first.content),
        shelf: shelf.gsub('-', '_').humanize
      }.compact
    end
  end
 end
