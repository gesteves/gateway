require 'rake/clean'
require 'dotenv/tasks'
require_relative 'lib/import'

CLOBBER.include %w{
  data/*.json
}

namespace :import do
  directory 'data'

  task :set_up_directories => %w{
    data
  }

  desc 'Imports photographs from Denali'
  task :denali => [:dotenv, :set_up_directories] do
    puts 'Importing photographs from Denali'
    Import::Denali.recent_photos(count: ENV['DENALI_COUNT'].to_i)
  end

  desc 'Imports repos & activity from Github'
  task :github => [:dotenv, :set_up_directories] do
    puts 'Importing repos & activity from Github'
    repos = YAML.load_file('data/featured_repos.yml')['repos']
    Import::Github.repos(repos: repos)
    Import::Github.contributions
end

  desc 'Imports books from Goodreads'
  task :goodreads => [:dotenv, :set_up_directories] do
    puts 'Importing books from Goodreads'
    goodreads = Import::Goodreads.new(api_key: ENV['GOODREADS_API_KEY'], rss_feed_url: ENV['GOODREADS_RSS_FEED'])
    goodreads.recent_books
    goodreads.photography_books
  end

  desc 'Imports albums from Spotify'
  task :spotify => [:dotenv, :set_up_directories] do
    puts 'Importing albums from Spotify'
    spotify = Import::Spotify.new
    spotify.top_albums
  end
end

task :import => %w{
  clobber
  import:github
  import:denali
  import:goodreads
  import:spotify
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts 'Building the site'
  sh 'middleman build'
end
