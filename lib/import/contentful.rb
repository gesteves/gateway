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
      query Content($skip: Int, $limit: Int) {
        articles: articleCollection(skip: $skip, limit: $limit, preview: true) {
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
        links: linkCollection(skip: $skip, limit: $limit, preview: true) {
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
        pages: pageCollection(skip: $skip, limit: $limit, preview: true, order: [title_ASC]) {
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
            bluesky
            flickr
            github
            instagram
            linkedin
            strava
            tumblr
            mastodon
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
        redirects: redirectCollection(skip: $skip, limit: $limit, order: [sys_publishedAt_DESC]) {
          items {
            from
            to
            status
          }
        }
        assets: assetCollection(skip: $skip, limit: $limit, preview: true, order: [sys_firstPublishedAt_DESC]) {
          items {
            sys {
              id
            }
            url
            width
            height
            description
            title
            contentType
          }
        }
      }
    GRAPHQL

    def self.query_contentful
      articles = []
      links = []
      pages = []
      assets = []
      redirects = []
      author = []
      home = []

      skip = 0
      limit = 1000
      loops = 0
      fetch = true

      while fetch
        response = Client.query(Queries::Content, variables: { skip: skip, limit: limit })
        loops += 1
        skip = loops * limit

        if response.data.articles.items.blank? && response.data.links.items.blank? && response.data.pages.items.blank? && response.data.assets.items.blank? && response.data.redirects.items.blank?
          fetch = false
        end

        articles += response.data.articles.items
        links += response.data.links.items
        pages += response.data.pages.items
        assets += response.data.assets.items
        redirects += response.data.redirects.items
        author += response.data.author.items
        home += response.data.home.items

        sleep 0.02
      end

      articles = articles.compact.map(&:to_h).map(&:with_indifferent_access)
      links = links.compact.map(&:to_h).map(&:with_indifferent_access)
      pages = pages.compact.map(&:to_h).map(&:with_indifferent_access)
      assets = assets.compact.map(&:to_h).map(&:with_indifferent_access)
      redirects = redirects.compact.map(&:to_h).map(&:with_indifferent_access)
      author = author.compact.map(&:to_h).map(&:with_indifferent_access).first
      home = home.compact.map(&:to_h).map(&:with_indifferent_access).first
      return articles, links, pages, assets, redirects, author, home
    end

    def self.content
      articles, links, pages, assets, redirects, author, home = query_contentful

      articles = articles
                  .map { |item| set_entry_type(item, 'Article') }
                  .map { |item| set_draft_status(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_article_path(item) }
                  .sort { |a,b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/articles.json','w'){ |f| f << articles.to_json }

      blog = generate_blog(articles)
      File.open('data/blog.json','w'){ |f| f << blog.to_json }

      tags = generate_tags(articles)
      File.open('data/tags.json','w'){ |f| f << tags.to_json }

      links = links
                  .map { |item| set_entry_type(item, 'Link') }
                  .map { |item| set_draft_status(item) }
                  .map { |item| set_timestamps(item) }
                  .map { |item| set_link_path(item) }
                  .sort { |a,b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/links.json','w'){ |f| f << links.to_json }

      link_blog = generate_link_blog(links)
      File.open('data/link_blog.json','w'){ |f| f << link_blog.to_json }

      tags = generate_link_tags(links)
      File.open('data/link_tags.json','w'){ |f| f << tags.to_json }

      pages = pages
                .map { |item| set_entry_type(item, 'Page') }
                .map { |item| set_draft_status(item) }
                .map { |item| set_timestamps(item) }
                .map { |item| set_page_path(item) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }

      File.open('data/author.json','w'){ |f| f << author.to_json }
      File.open('data/home.json','w'){ |f| f << home.to_json }
      File.open('data/redirects.json','w'){ |f| f << redirects.to_json }
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
        tag[:items] = articles.select { |a| !a[:draft] && a.dig(:contentfulMetadata, :tags).include?(tag) }
        tag[:path] = "/blog/tags/#{tag[:id]}/index.html"
        tag[:title] = "Articles tagged “#{tag[:name]}”"
        tag[:indexInSearchEngines] = true
        tag
      end
      tags.select { |t| t[:items].present? }.sort { |a, b| a[:id] <=> b[:id] }
    end

    def self.generate_link_tags(links)
      tags = links.map { |a| a.dig(:contentfulMetadata, :tags) }.flatten.uniq
      tags.map! do |tag|
        tag = tag.dup
        tag[:items] = links.select { |a| !a[:draft] && a.dig(:contentfulMetadata, :tags).include?(tag) }
        tag[:path] = "/links/tags/#{tag[:id]}/index.html"
        tag[:title] = "Links tagged “#{tag[:name]}”"
        tag[:indexInSearchEngines] = true
        tag
      end
      tags.select { |t| t[:items].present? }.sort { |a, b| a[:id] <=> b[:id] }
    end

    def self.generate_blog(articles)
      blog = []
      sliced = articles.reject { |a| a[:draft] }.each_slice(10)
      sliced.each_with_index do |page, index|
        blog << {
          current_page: index + 1,
          previous_page: index == 0 ? nil : index,
          next_page: index == sliced.size - 1 ? nil : index + 2,
          title: "Blog",
          items: page,
          entry_type: "Article"
        }
      end
      blog
    end

    def self.generate_link_blog(links)
      blog = []
      sliced = links.reject { |a| a[:draft] }.each_slice(10)
      sliced.each_with_index do |page, index|
        blog << {
          current_page: index + 1,
          previous_page: index == 0 ? nil : index,
          next_page: index == sliced.size - 1 ? nil : index + 2,
          title: "Links",
          items: page,
          entry_type: "Link"
        }
      end
      blog
    end
  end
end
