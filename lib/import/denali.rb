require 'graphql/client'
require 'graphql/client/http'

module Import
  module Denali
    HTTP = GraphQL::Client::HTTP.new('https://www.allencompassingtrip.com/graphql')
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
    RecentEntriesQuery = Client.parse <<-'GRAPHQL'
      query ($count: Int) {
        blog {
          name
          entries(count: $count) {
            id
            url
            plainTitle
            photos {
              altText
              thumbnailUrls
            }
          }
        }
      }
    GRAPHQL

    def self.get_photos
      response = Client.query(RecentEntriesQuery, variables: { count: 4 })
      response.data.blog.entries.map { |e| File.open("source/images/denali/#{e.id}.jpg",'w'){ |f| f << HTTParty.get(e.photos.first.thumbnail_urls.first).body } }
      File.open('data/denali.json','w'){ |f| f << response.data.to_h.to_json }
    end
  end
end
