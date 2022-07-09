# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

configure :development do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
  config[:imgix_token]         = ENV['IMGIX_TOKEN']
  config[:imgix_domain]        = ENV['IMGIX_DOMAIN']
  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :asset_hash
  activate :relative_assets
  activate :directory_indexes
  set :markdown, smartypants: true

  data.articles.each do |article|
    proxy article.path, "/contentful.html", locals: { content: article, content_type: 'article' }, ignore: true
  end

  data.pages.each do |page|
    proxy page.path, "/contentful.html", locals: { content: page, content_type: 'page' }, ignore: true
  end
end

configure :production do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
  config[:imgix_token]         = ENV['IMGIX_TOKEN']
  config[:imgix_domain]        = ENV['IMGIX_DOMAIN']
  config[:url]                 = ENV['URL']
  config[:deploy_url]          = ENV['DEPLOY_URL']
  config[:context]             = ENV['CONTEXT']
  config[:netlify]             = ENV['NETLIFY']
  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :minify_css
  activate :minify_javascript
  activate :minify_html
  activate :asset_hash
  activate :directory_indexes
  set :markdown, smartypants: true

  page "/404.html", directory_index: false

  data.articles.each do |article|
    proxy article.path, "/contentful.html", locals: { content: article, content_type: 'article' }, ignore: true
  end

  data.pages.each do |page|
    proxy page.path, "/contentful.html", locals: { content: page, content_type: 'page' }, ignore: true
  end
end
