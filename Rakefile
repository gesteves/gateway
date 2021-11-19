require 'dotenv/tasks'

desc 'Import content and build the site'
task :build => [:dotenv] do
  puts 'Building the site'
  sh 'middleman build'
end
