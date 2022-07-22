require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'
require 'active_support/all'

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
        articles: articleCollection(limit: 1000, preview: true) {
          items {
            title
            slug
            body
            author {
              name
            }
            summary
            published
            indexInSearchEngines
            canonicalUrl
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
        links: linkCollection(limit: 1000, preview: true) {
          items {
            title
            slug
            body
            author {
              name
            }
            linkUrl
            published
            indexInSearchEngines
            noFollow
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
        pages: pageCollection(limit: 1000, preview: true, order: [title_ASC]) {
          items {
            title
            slug
            body
            summary
            indexInSearchEngines
            canonicalUrl
            showInNav
            showInFooter
            menuLabel
            sys {
              id
              firstPublishedAt
              publishedAt
              publishedVersion
            }
          }
        }
        author: authorCollection(limit: 1, order: [sys_firstPublishedAt_ASC]) {
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
        home: homeCollection(limit: 1, order: [sys_firstPublishedAt_ASC]) {
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
        redirects: redirectCollection(limit: 1000, order: [sys_publishedAt_DESC]) {
          items {
            from
            to
            status
          }
        }
        assets: assetCollection(limit: 1000, preview: true, order: [sys_firstPublishedAt_DESC]) {
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
                  .articles
                  .items
                  .map(&:to_h)
                  .map(&:with_indifferent_access)
                  .map { |item| set_entry_type(item, 'Article') }
                  .map { |item| set_draft_status(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_article_path(item) }
                  .sort { |a,b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/articles.json','w'){ |f| f << articles.to_json }

      tags = generate_tags(articles)
      File.open('data/tags.json','w'){ |f| f << tags.to_json }

      links = response
                  .data
                  .links
                  .items
                  .map(&:to_h)
                  .map(&:with_indifferent_access)
                  .map { |item| set_entry_type(item, 'Link') }
                  .map { |item| set_draft_status(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_link_path(item) }
                  .sort { |a,b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/links.json','w'){ |f| f << links.to_json }

      tags = generate_link_tags(links)
      File.open('data/link_tags.json','w'){ |f| f << tags.to_json }

      pages = response
                .data
                .pages
                .items
                .map(&:to_h)
                .map(&:with_indifferent_access)
                .map { |item| set_entry_type(item, 'Page') }
                .map { |item| set_draft_status(item) }
                .map { |item| set_timestamps(item) }
                .map { |item| set_page_path(item) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }

      author = response
                .data
                .author
                .items
                .map(&:to_h)
                .map(&:with_indifferent_access)
                .first
      File.open('data/author.json','w'){ |f| f << author.to_json }

      home = response
              .data
              .home
              .items
              .map(&:to_h)
              .map(&:with_indifferent_access)
              .first
      File.open('data/home.json','w'){ |f| f << home.to_json }

      redirects = response
                  .data
                  .redirects
                  .items
                  .map(&:to_h)
                  .map(&:with_indifferent_access)
      File.open('data/redirects.json','w'){ |f| f << redirects.to_json }

      assets = response
                .data
                .assets
                .items
                .map(&:to_h)
                .map(&:with_indifferent_access)
      File.open('data/assets.json','w'){ |f| f << assets.to_json }
    end

    def self.set_entry_type(item, type)
      item[:entry_type] = type
      item
    end

    def self.set_draft_status(item)
      draft = item.dig(:sys, :publishedVersion).blank?
      item[:draft] = draft
      item[:indexInSearchEngines] = false if draft
      item
    end

    def self.set_article_path(item)
      if item[:draft]
        item[:path] = "/id/#{item.dig(:sys, :id)}/index.html"
      else
        published = DateTime.parse(item[:published_at])
        item[:path] = "/blog/#{published.strftime('%Y')}/#{published.strftime('%m')}/#{published.strftime('%d')}/#{item[:slug]}/index.html"
      end
      item
    end

    def self.set_link_path(item)
      if item[:draft]
        item[:path] = "/id/#{item.dig(:sys, :id)}/index.html"
      else
        published = DateTime.parse(item[:published_at])
        item[:path] = "/links/#{published.strftime('%Y')}/#{published.strftime('%m')}/#{published.strftime('%d')}/#{item[:slug]}/index.html"
      end
      item
    end

    def self.set_page_path(item)
      if item[:draft]
        item[:path] = "/id/#{item.dig(:sys, :id)}/index.html"
      else
        item[:path] = "/#{item[:slug]}/index.html"
      end
      item
    end

    def self.set_timestamps(item)
      item[:published_at] = item.dig(:published) || item.dig(:sys, :firstPublishedAt) || Time.now.to_s
      item[:updated_at] = item.dig(:sys, :publishedAt) || Time.now.to_s
      item
    end

    def self.generate_tags(articles)
      tags = articles.map { |a| a.dig(:contentfulMetadata, :tags) }.flatten.uniq
      tags.map! do |tag|
        tag = tag.dup
        tag[:articles] = articles.select { |a| !a[:draft] && a.dig(:contentfulMetadata, :tags).include?(tag) }
        tag[:path] = "/blog/tags/#{tag[:id]}/index.html"
        tag[:title] = tag[:name]
        tag[:summary] = "Articles tagged “#{tag[:name]}”"
        tag[:indexInSearchEngines] = true
        tag
      end
      tags.select { |t| t[:articles].present? }.sort { |a, b| a[:id] <=> b[:id] }
    end

    def self.generate_link_tags(links)
      tags = links.map { |a| a.dig(:contentfulMetadata, :tags) }.flatten.uniq
      tags.map! do |tag|
        tag = tag.dup
        tag[:links] = links.select { |a| !a[:draft] && a.dig(:contentfulMetadata, :tags).include?(tag) }
        tag[:path] = "/links/tags/#{tag[:id]}/index.html"
        tag[:title] = tag[:name]
        tag[:summary] = "Links tagged “#{tag[:name]}”"
        tag[:indexInSearchEngines] = true
        tag
      end
      tags.select { |t| t[:links].present? }.sort { |a, b| a[:id] <=> b[:id] }
    end
  end
end
