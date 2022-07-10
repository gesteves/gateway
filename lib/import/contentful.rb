require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'

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
        articleCollection(limit: 1000, preview: true, order: [published_DESC, sys_publishedAt_DESC]) {
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
              id
              firstPublishedAt
              publishedAt
              publishedVersion
            }
            contentfulMetadata {
              tags {
                id
                name
              }
            }
          }
        }
        pageCollection(limit: 1000, preview: true, order: [title_ASC, sys_publishedAt_ASC]) {
          items {
            title
            slug
            body
            summary
            indexInSearchEngines
            sys {
              id
              firstPublishedAt
              publishedAt
              publishedVersion
            }
          }
        }
        authorCollection(limit: 1, order: [sys_firstPublishedAt_ASC]) {
          items {
            name
            email
            flickr
            github
            instagram
            linkedin
            strava
            twitter
            profilePicture {
              width
              height
              url
              title
            }
          }
        }
        homeCollection(limit: 1, order: [sys_firstPublishedAt_ASC]) {
          items {
            title
            summary
            eyebrow
            heading
            linkText
            linkUrl
            lightImageLandscape {
              url
            }
            lightImagePortrait {
              url
            }
            darkImageLandscape {
              url
            }
            darkImagePortrait {
              url
            }
            altText
            sys {
              publishedAt
            }
          }
        }
        redirectCollection(limit: 1000, order: [sys_publishedAt_DESC]) {
          items {
            from
            to
            status
          }
        }
        assetCollection(limit: 1000, preview: true) {
          items {
            sys {
              id
            }
            url
            width
            height
            description
            title
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
                  .map(&:to_h)
                  .map { |item| set_draft_status(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_entry_path(item) }
      File.open('data/articles.json','w'){ |f| f << articles.to_json }

      tags = generate_tags(articles)
      File.open('data/tags.json','w'){ |f| f << tags.to_json }

      pages = response
                .data
                .page_collection
                .items
                .map(&:to_h)
                .map { |item| set_draft_status(item) }
                .map { |item| set_timestamps(item) }
                .map { |item| set_page_path(item) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }

      author = response
                .data
                .author_collection
                .items
                .map(&:to_h)
                .first
      File.open('data/author.json','w'){ |f| f << author.to_json }

      home = response
              .data
              .home_collection
              .items
              .map(&:to_h)
              .first
      File.open('data/home.json','w'){ |f| f << home.to_json }

      redirects = response
                  .data
                  .redirect_collection
                  .items
                  .map(&:to_h)
      File.open('data/redirects.json','w'){ |f| f << redirects.to_json }

      assets = response
                .data
                .asset_collection
                .items
                .map(&:to_h)
      File.open('data/assets.json','w'){ |f| f << assets.to_json }
    end

    def self.set_draft_status(item)
      item = item.dup
      item[:draft] = item.dig('sys', 'publishedVersion').blank?
      item
    end

    def self.set_entry_path(item)
      item = item.dup
      if item[:draft]
        item[:path] = "/blog/#{item.dig('sys', 'id')}/index.html"
      else
        published = DateTime.parse(item[:published_at])
        item[:path] = "/blog/#{published.strftime('%Y')}/#{published.strftime('%m')}/#{published.strftime('%d')}/#{item['slug']}/index.html"
      end
      item
    end

    def self.set_page_path(item)
      item = item.dup
      if item[:draft]
        item[:path] = "/page/#{item.dig('sys', 'id')}/index.html"
      else
        item[:path] = "/#{item['slug']}/index.html"
      end
      item
    end

    def self.set_timestamps(item)
      item = item.dup
      item[:published_at] = item.dig('published') || item.dig('sys', 'firstPublishedAt') || Time.now.to_s
      item[:updated_at] = item.dig('sys', 'publishedAt') || Time.now.to_s
      item
    end

    def self.generate_tags(articles)
      tags = articles.map { |a| a.dig('contentfulMetadata', 'tags') }.flatten.uniq
      tags.map! do |tag|
        tag = tag.dup
        tag[:articles] = articles.select { |a| !a[:draft] && a.dig('contentfulMetadata', 'tags').include?(tag) }
        tag[:path] = "/blog/tags/#{tag['id']}/index.html"
        tag[:title] = tag['name']
        tag[:summary] = "Articles tagged “#{tag[:name]}”"
        tag[:indexInSearchEngines] = true
        tag
      end
      tags.select { |t| t[:articles].present? }.sort { |a, b| a['id'] <=> b['id'] }
    end
  end
end
