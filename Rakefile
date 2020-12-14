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
end

task :import => %w{
  clobber
  import:github
  import:denali
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts 'Building the site'
  sh 'middleman build'
end
