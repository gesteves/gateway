require 'nokogiri'
require 'httparty'

module Import
  class Goodreads
    def initialize(feed, count)
      @feed = feed
      @book_count = count
    end

    def get_books
      books = []
      ['currently-reading', 'read'].each do |shelf|
        books << get_shelf(shelf)
      end
      books = books.flatten.slice(0, @book_count)
      books.map { |b| save_image(b) }
      File.open('data/goodreads.json','w'){ |f| f << books.to_json }
    end

    def get_shelf(shelf)
      rss_feed = @feed + "&shelf=#{shelf}"
      books = []
      Nokogiri::XML(HTTParty.get(rss_feed).body).css('item').sort { |a,b|  Time.parse(b.css('user_date_created').text) <=> Time.parse(a.css('user_date_created').text)}.each do |item|
        book = {
          id: item.css('book_id').first.content,
          title: item.css('title').first.content,
          author: item.css('author_name').first.content,
          image_url: item.css('book_large_image_url').first.content,
          url: Nokogiri.HTML(item.css('description').first.content).css('a').first['href'].gsub('?utm_medium=api&utm_source=rss', ''),
          published: item.css('book_published').first.content,
          shelf: shelf
        }
        books << book
      end
      books
    end

    def save_image(book)
      File.open("source/images/goodreads/#{book[:id]}.jpg",'w'){ |f| f << HTTParty.get(book[:image_url]).body }
    end
  end
end
