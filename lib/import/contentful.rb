require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'
require 'rdoc'

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

      articles = response.data.article_collection.items.map { |item| render_body(item) }.map { |item| set_timestamps(item) }.map { |item| set_entry_path(item) }
      File.open('data/articles.json','w'){ |f| f << articles.to_json }

      pages = response.data.page_collection.items.map { |item| render_body(item) }.map { |item| set_timestamps(item) }.map { |item| set_entry_path(item) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }
    end

    def self.render_body(item)
      formatter = RDoc::Markup::ToHtml.new(RDoc::Options.new, nil)
      html = RDoc::Markdown.parse(item.body).accept(formatter)
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
  end
end
