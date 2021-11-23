require 'rake/clean'
require 'dotenv/tasks'
require_relative 'lib/import'
require 'yaml'

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
    puts 'Importing repos from Github'
    repos = YAML.load_file('data/featured_repos.yml')['repos']
    Import::Github.repos(repos: repos)
  end

  desc 'Imports books from Goodreads'
  task :goodreads => [:dotenv, :set_up_directories] do
    puts 'Importing books from Goodreads'
    goodreads = Import::Goodreads.new(api_key: ENV['GOODREADS_API_KEY'], rss_feed_url: ENV['GOODREADS_RSS_FEED'])
    goodreads.recent_books
  end

  desc 'Imports movies from Letterboxd'
  task :letterboxd => [:dotenv, :set_up_directories] do
    puts 'Importing movies from Letterboxd'
    letterboxd = Import::Letterboxd.new(rss_feed_url: ENV['LETTERBOXD_RSS_FEED'], count: ENV['LETTERBOXD_COUNT'].to_i)
    letterboxd.recent_movies
  end

  desc 'Imports music from Last.fm'
  task :lastfm => [:dotenv, :set_up_directories] do
    puts 'Importing music from Last.fm'
    lastfm = Import::Lastfm.new(api_key: ENV['LASTFM_API_KEY'], user: ENV['LASTFM_USERNAME'], count: ENV['LASTFM_COUNT'].to_i)
    lastfm.top_tracks
  end
end

task :import => %w{
  clobber
  import:github
  import:denali
  import:goodreads
  import:letterboxd
  import:lastfm
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts 'Building the site'
  sh 'middleman build'
end
