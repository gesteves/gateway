require 'graphql/client'
require 'graphql/client/http'

module Import
  module Denali
    HTTP = GraphQL::Client::HTTP.new('https://www.allencompassingtrip.com/graphql')
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
    Queries = Client.parse <<-'GRAPHQL'
      query RecentEntries($count: Int) {
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

    def self.recent_photos(count:)
      response = Client.query(Queries::RecentEntries, variables: { count: count })
      File.open('data/photographs.json','w'){ |f| f << response.data.to_h.to_json }
    end
  end
end
