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
        articleCollection(limit: 1000, preview: true) {
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
        pageCollection(limit: 1000, preview: true) {
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
        authorCollection(limit: 1) {
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
        homeCollection(limit: 1) {
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
      }
    GRAPHQL

    def self.content
      response = Client.query(Queries::Content)

      articles = response
                  .data
                  .article_collection
                  .items
                  .map { |item| render_body(item) }
                  .map { |item| set_draft_status(item) }
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
                .map { |item| set_draft_status(item) }
                .map { |item| optimize_images(item) }
                .map { |item| set_timestamps(item) }
                .map { |item| set_page_path(item) }
                .sort { |a, b| DateTime.parse(b[:published_at]) <=> DateTime.parse(a[:published_at]) }
      File.open('data/pages.json','w'){ |f| f << pages.to_json }

      author = response
                .data
                .author_collection
                .items
                .first
                .to_h
      File.open('data/author.json','w'){ |f| f << author.to_json }

      home = response
              .data
              .home_collection
              .items
              .first
              .to_h
      File.open('data/home.json','w'){ |f| f << home.to_json }
    end

    def self.render_body(item)
      if item.body.present?
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
        html = Redcarpet::Render::SmartyPants.render(markdown.render(item.body))
        item = item.to_h.dup
        item[:html] = html
      else
        item = item.to_h.dup
        item[:html] = nil
      end
      item
    end

    def self.set_draft_status(item)
      item = item.to_h.dup
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
      item[:path] = "/#{item['slug']}/index.html"
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

    def self.optimize_images(item)
      srcset_widths = [576, 686, 764, 1146, 1074, 1384, 1600]
      sizes = "(min-width: 930px) 800px, (min-width: 768px) calc(100vw - 8 rem), calc(100vw - 2rem)"
      formats = ['avif', 'webp', 'jpg']

      item = item.dup
      doc = Nokogiri::HTML::DocumentFragment.parse(item[:html])
      # Loop through every image tag in a paragraph,
      # which is what Markdown generates.

      doc.css('p > img').each do |img|
        # Parse the URL of the image, we'll need it later.
        src = URI.parse(img['src'])

        # Get the parent paragraph of the image
        paragraph = img.parent
        # Remove the image
        img = img.remove
        # The caption is whatever is left in the paragraph, store it...
        caption = paragraph.inner_html
        # ...then put the image back
        paragraph.prepend_child(img)

        # Add srcset/sizes to the base img, and make it lazy load.
        img['sizes'] = sizes
        srcset = srcset_widths.map do |w|
          query = { w: w }
          src.query = URI.encode_www_form(query)
          "#{src.to_s} #{w}w"
        end
        img['srcset'] = srcset.join(', ')
        img['loading'] = 'lazy'

        # Then wrap it in a picture element.
        img.wrap('<picture></picture>')

        # Add a source element for each image format,
        # as a sibling of the img element in the picture tag.
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

        # If there's a caption under the image, wrap the whole thing in a figure element,
        # with the caption in a figcaption,
        # then replace the original paragraph with it.
        if caption.present?
          img.parent.wrap('<figure></figure>')
          img.add_next_sibling("<figcaption>#{caption}</figcaption>")
          paragraph.replace(img.parent.parent)
        else
          # If there's no caption, simply replace the original paragraph
          # with the picture element.
          paragraph.replace(img.parent)
        end
      end
      item[:html] = doc.to_html
      item
    end
  end
end
