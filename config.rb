# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

configure :development do
  config[:css_dir]       = 'stylesheets'
  config[:js_dir]        = 'javascripts'
  config[:images_dir]    = 'images'
  config[:imgix_token]   = ENV['IMGIX_TOKEN']
  config[:imgix_domain]  = ENV['IMGIX_DOMAIN']
  config[:gravatar_email] = ENV['GRAVATAR_EMAIL']
  config[:environment]   = ENV['RACK_ENV']

  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :minify_html
end

configure :production do
  config[:css_dir]       = 'stylesheets'
  config[:js_dir]        = 'javascripts'
  config[:images_dir]    = 'images'
  config[:imgix_token]   = ENV['IMGIX_TOKEN']
  config[:imgix_domain]  = ENV['IMGIX_DOMAIN']
  config[:gravatar_email] = ENV['GRAVATAR_EMAIL']
  config[:environment]   = ENV['RACK_ENV']

  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :minify_css
  activate :minify_html
  activate :asset_hash
  activate :relative_assets
end
