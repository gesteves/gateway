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
    begin
      puts '== Importing Denali photos'
      start_time = Time.now
      Import::Denali.get_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Denali photos: #{e}"
    end
  end

  desc 'Import data from Goodreads'
  task :goodreads => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing data from Goodreads'
      start_time = Time.now
      goodreads = Import::Goodreads.new(ENV['GOODREADS_RSS_FEED'], ENV['GOODREADS_COUNT'].to_i)
      goodreads.get_books
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Goodreads data: #{e}"
    end
  end

  desc 'Import data from Untappd'
  task :untappd => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing data from Untappd'
      start_time = Time.now
      untappd = Import::Untappd.new(ENV['UNTAPPD_USERNAME'], ENV['UNTAPPD_CLIENT_ID'], ENV['UNTAPPD_CLIENT_SECRET'], ENV['UNTAPPD_COUNT'].to_i)
      untappd.get_beers
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Untappd data: #{e}"
    end
  end

  desc 'Import data from Spotify'
  task :spotify => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Spotify data'
      start_time = Time.now
      spotify = Import::Spotify.new(ENV['SPOTIFY_REFRESH_TOKEN'])
      spotify.get_albums
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Spotify data: #{e}"
    end
  end

  desc 'Import Gravatar'
  task :gravatar => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Gravatar'
      start_time = Time.now
      gravatar = Import::Gravatar.new(ENV['GRAVATAR_EMAIL'])
      gravatar.save_avatar
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Gravatar: #{e}"
    end
  end
end

task :import => %w{
  clobber
  import:goodreads
  import:untappd
  import:spotify
  import:denali
  import:gravatar
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts '== Building the site'
  system('middleman build')
end
