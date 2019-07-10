require 'rake/clean'
require 'dotenv/tasks'
require_relative 'lib/import'

CLOBBER.include('data/*.json', 'source/images/denali/*', 'source/images/gravatar/*', 'source/images/goodreads/*', 'source/images/lastfm/*')

namespace :import do
  directory 'data'
  directory 'source/images/denali'
  directory 'source/images/gravatar'
  directory 'source/images/goodreads'
  directory 'source/images/lastfm'

  task :set_up_directories => ['data', 'source/images/denali', 'source/images/gravatar', 'source/images/goodreads', 'source/images/lastfm']

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

  desc 'Import data from Last.fm'
  task :lastfm => [:dotenv, :set_up_directories] do
    # begin
      puts '== Importing Last.fm data'
      start_time = Time.now
      lastfm = Import::Lastfm.new(ENV['LASTFM_API_KEY'], ENV['LASTFM_USERNAME'])
      lastfm.get_albums
      puts "Completed in #{Time.now - start_time} seconds"
    # rescue => e
    #   abort "Failed to import Last.fm data: #{e}"
    # end
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
  import:lastfm
  import:denali
  import:gravatar
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts '== Building the site'
  system('middleman build')
end
