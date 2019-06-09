require 'rake/clean'
require 'dotenv/tasks'
require 'aws-sdk-cloudfront'
require_relative 'lib/import'

CLOBBER.include('data/*.json', 'source/images/denali/*', 'source/images/gravatar/*', 'source/images/goodreads/*', 'source/images/spotify/*')

namespace :import do
  directory 'data'
  directory 'source/images/denali'
  directory 'source/images/gravatar'
  directory 'source/images/goodreads'
  directory 'source/images/spotify'

  task :set_up_directories => ['data', 'source/images/denali', 'source/images/gravatar', 'source/images/goodreads', 'source/images/spotify']

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

  desc 'Import data from Spotify'
  task :spotify => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Spotify data'
      start_time = Time.now
      music = Import::Spotify.new(ENV['SPOTIFY_REFRESH_TOKEN'])
      music.get_albums
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Music data: #{e}"
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
  import:spotify
  import:denali
  import:gravatar
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts '== Building the site'
  system('middleman build')
end

desc 'Sync the site to S3'
task :sync do
  puts '== Syncing with S3'
  system('middleman s3_sync')
end

desc 'Publishes the site'
task :publish => [:build, :sync]

namespace :publish do
  desc 'Publishes the site and invalidates in CloudFront'
  task :hard => [:publish, :invalidate]
end

desc 'Send CloudFront invalidation request'
task :invalidate => [:dotenv] do
  unless ENV['AWS_CLOUDFRONT_DISTRIBUTION_ID'].nil?
    puts '== Sending CloudFront invalidation request'
    start_time = Time.now
    client = Aws::CloudFront::Client.new(access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY_ID'], region: ENV['AWS_REGION'])
    paths = ['/'].compact
    response = client.create_invalidation({
      distribution_id: ENV['AWS_CLOUDFRONT_DISTRIBUTION_ID'],
      invalidation_batch: {
        paths: {
          quantity: paths.size,
          items: paths,
        },
        caller_reference: Time.now.to_i.to_s,
      },
    })
    puts "Completed in #{Time.now - start_time} seconds"
  end
end
