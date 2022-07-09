require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'
require 'redcarpet'
require 'nokogiri'

module Import
  module Contentful
    Dotenv.load
    HTTP = GraphQL::Client::HTTP.new("https://graphql.contentful.com/content/v1/spaces/#{ENV['CONTENTFUL_SPACE']}")do
      def headers(context)
        { "Authorization": "Bearer #{ENV['CONTENTFUL_TOKEN']}" }
      end
    end
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
    Queries = Client.parse <<-'GRAPHQL'
      query Content {
        articleCollection(limit: 1000) {
          items {
            title
            slug
            body
            author {
              name
            }
            linkUrl
            summary
            published
            indexInSearchEngines
            sys {
              firstPublishedAt
              publishedAt
            }
            contentfulMetadata {
              tags {
                id
                name
              }
            }
          }
        }
        pageCollection(limit: 1000) {
          items {
            title
            slug
            body
            summary
            sys {
              firstPublishedAt
              publishedAt
            }
          }
        }
      }
    GRAPHQL

    def self.content
      response = Client.query(Queries::Content)

      articles = response
                  .data
                  .article_collection
                  .items
                  .map { |item| render_body(item) }
                  .map { |item| optimize_images(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_entry_path(item) }
                  .sort { |a, b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/articles.json','w'){ |f| f << articles.to_json }

      tags = generate_tags(articles)
      File.open('data/tags.json','w'){ |f| f << tags.to_json }

      pages = response
                .data
                .page_collection
                .items
                .map { |item| render_body(item) }
                .map { |item| optimize_images(item) }
                .map { |item| set_timestamps(item) }
                .map { |item| set_page_path(item) }
                .sort { |a, b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }
    end

    def self.render_body(item)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      html = Redcarpet::Render::SmartyPants.render(markdown.render(item.body))
      item = item.to_h.dup
      item[:html] = html
      item
    end

    def self.set_entry_path(item)
      item = item.dup
      published = DateTime.parse(item[:published_at])
      item[:path] = "/blog/#{published.strftime('%Y')}/#{published.strftime('%m')}/#{published.strftime('%d')}/#{item['slug']}/index.html"
      item
    end

    def self.set_page_path(item)
      item = item.dup
      item[:path] = "/#{item['slug']}/index.html"
      item
    end

    def self.set_timestamps(item)
      item = item.dup
      item[:published_at] = item.dig('published') || item.dig('sys', 'firstPublishedAt')
      item[:updated_at] = item.dig('sys', 'publishedAt')
      item
    end

    def self.generate_tags(articles)
      tags = articles.map { |a| a.dig('contentfulMetadata', 'tags') }.flatten.uniq
      tags.map! do |tag|
        tag = tag.dup
        tag[:articles] = articles.select { |a| a.dig('contentfulMetadata', 'tags').include? tag }
        tag[:path] = "/blog/tags/#{tag['id']}/index.html"
        tag[:title] = tag['name']
        tag[:summary] = "Articles tagged “#{tag[:name]}”"
        tag
      end
      tags
    end

    def self.optimize_images(item)
      srcset_widths = [576, 686, 764, 1146, 1074, 1384, 1600]
      sizes = "(min-width: 930px) 800px, (min-width: 768px) calc(100vw - 8 rem), calc(100vw - 2rem)"
      formats = ['avif', 'webp', 'jpg']

      item = item.dup
      doc = Nokogiri::HTML::DocumentFragment.parse(item[:html])
      doc.css('p img').each do |img|
        src = URI.parse(img['src'])
        parent = img.parent
        img['sizes'] = sizes
        srcset = srcset_widths.map do |w|
          query = { w: w }
          src.query = URI.encode_www_form(query)
          "#{src.to_s} #{w}w"
        end
        img['srcset'] = srcset.join(', ')
        img['loading'] = 'lazy'
        img.wrap('<picture></picture>')

        formats.each do |format|
          srcset = srcset_widths.map do |w|
            query = { w: w, fm: format }
            src.query = URI.encode_www_form(query)
            "#{src.to_s} #{w}w"
          end
          srcset = srcset.join(', ')
          type = "image/#{format}"
          img.add_previous_sibling("<source srcset=\"#{srcset}\" sizes=\"#{sizes}\" type=\"#{type}\" />")
        end
        parent.replace(img.parent)
      end
      item[:html] = doc.to_html
      item
    end
  end
end
