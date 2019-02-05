desc 'Build the site'
task :build do
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