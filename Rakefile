require 'rake/clean'
require 'dotenv/tasks'
require_relative 'lib/import'

CLOBBER.include('data/*.json', 'source/images/denali/*', 'source/images/gravatar/*', 'source/images/goodreads/*', 'source/images/spotify/*', 'source/images/untappd/*')

namespace :import do
  directory 'data'
  directory 'source/images/denali'
  directory 'source/images/gravatar'
  directory 'source/images/goodreads'
  directory 'source/images/untappd'
  directory 'source/images/spotify'

  task :set_up_directories => ['data', 'source/images/denali', 'source/images/gravatar', 'source/images/goodreads', 'source/images/spotify', 'source/images/untappd']

  desc 'Import latest Denali photos'
  task :denali => [:dotenv, :set_up_directories] do
    puts '== Importing Denali photos'
    start_time = Time.now
    Import::Denali.recent_photos(ENV['DENALI_COUNT'].to_i)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc 'Import featured repos from Github'
  task :github => [:dotenv, :set_up_directories] do
    puts '== Importing Github data'
    start_time = Time.now
    repos = YAML.load_file('data/repos.yml')['repos']
    Import::Github.repos(repos)
    Import::Github.contributions
    puts "Completed in #{Time.now - start_time} seconds"
end

  desc 'Import data from Goodreads'
  task :goodreads => [:dotenv, :set_up_directories] do
    puts '== Importing data from Goodreads'
    start_time = Time.now
    goodreads = Import::Goodreads.new(ENV['GOODREADS_RSS_FEED'])
    goodreads.recent_books(ENV['GOODREADS_COUNT'].to_i)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc 'Import data from Untappd'
  task :untappd => [:dotenv, :set_up_directories] do
    puts '== Importing data from Untappd'
    start_time = Time.now
    untappd = Import::Untappd.new(ENV['UNTAPPD_USERNAME'], ENV['UNTAPPD_CLIENT_ID'], ENV['UNTAPPD_CLIENT_SECRET'])
    untappd.recent_beers(ENV['UNTAPPD_COUNT'].to_i)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc 'Import data from Spotify'
  task :spotify => [:dotenv, :set_up_directories] do
    puts '== Importing Spotify data'
    start_time = Time.now
    spotify = Import::Spotify.new
    spotify.recent_albums(ENV['SPOTIFY_COUNT'].to_i)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc 'Import Gravatar'
  task :gravatar => [:dotenv, :set_up_directories] do
    puts '== Importing Gravatar'
    start_time = Time.now
    gravatar = Import::Gravatar.new(ENV['GRAVATAR_EMAIL'])
    gravatar.save_avatar
    puts "Completed in #{Time.now - start_time} seconds"
  end
end

task :import => %w{
  clobber
  import:gravatar
  import:github
  import:denali
  import:goodreads
  import:spotify
  import:untappd
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts '== Building the site'
  system('middleman build')
end
