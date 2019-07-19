# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

configure :development do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
  config[:imgix_token]         = ENV['IMGIX_TOKEN']
  config[:imgix_domain]        = ENV['IMGIX_DOMAIN']
  config[:gravatar_email]      = ENV['GRAVATAR_EMAIL']
  config[:typekit_id]          = ENV['TYPEKIT_ID']

  activate :blog do |blog|
    blog.layout = "blog"
    blog.prefix = "blog"
    blog.sources = "{year}-{month}-{day}-{title}.html"
    blog.permalink = "{year}/{month}/{day}/{title}.html"
  end
  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :asset_hash
  activate :relative_assets
  activate :directory_indexes
end

configure :production do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
  config[:imgix_token]         = ENV['IMGIX_TOKEN']
  config[:imgix_domain]        = ENV['IMGIX_DOMAIN']
  config[:gravatar_email]      = ENV['GRAVATAR_EMAIL']
  config[:typekit_id]          = ENV['TYPEKIT_ID']
  config[:deploy_url]          = ENV['DEPLOY_URL']

  activate :blog do |blog|
    blog.layout = "blog"
    blog.prefix = "blog"
    blog.sources = "{year}-{month}-{day}-{title}.html"
    blog.permalink = "{year}/{month}/{day}/{title}.html"
  end
  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :minify_css
  activate :minify_html
  activate :asset_hash
  activate :relative_assets
  activate :directory_indexes
end
