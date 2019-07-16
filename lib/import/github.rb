require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'
require 'active_support/all'

module Import
  module Github
    Dotenv.load
    HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
      def headers(context)
        { "Authorization": "Bearer #{ENV['GITHUB_ACCESS_TOKEN']}" }
      end
    end
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
    Queries = Client.parse <<-'GRAPHQL'
      query Repo($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
          nameWithOwner
          description
          url
        }
      }
      query Contributions($from: DateTime) {
        viewer {
          contributionsCollection(from: $from) {
            totalCommitContributions
            totalPullRequestContributions
            totalPullRequestReviewContributions
            totalRepositoriesWithContributedCommits
          }
        }
      }
    GRAPHQL

    def self.repos(repos)
      data = repos.map { |r| self.query_repo(r) }
      File.open('data/github.json','w'){ |f| f << data.to_json }
    end

    def self.query_repo(repo)
      owner = repo.split('/').first
      name = repo.split('/').last
      response = Client.query(Queries::Repo, variables: { owner: owner, name: name })
      response.data.to_h
    end

    def self.contributions
      from = 1.month.ago
      response = Client.query(Queries::Contributions, variables: { from: 1.month.ago.utc.iso8601 })
      File.open('data/contributions.json','w'){ |f| f << response.data.to_h.to_json }
    end
  end
end
