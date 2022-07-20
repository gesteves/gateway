# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

configure :development do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
  activate :gzip
  activate :dotenv
  activate :autoprefixer do |config|
    config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
  end
  activate :asset_hash
  activate :relative_assets
  activate :directory_indexes

  data.articles.each do |article|
    proxy article.path, "/article.html", locals: { content: article }, ignore: true
  end

  data.links.each do |link|
    proxy article.path, "/link.html", locals: { content: link }, ignore: true
  end

  data.pages.each do |page|
    proxy page.path, "/page.html", locals: { content: page }, ignore: true
  end

  data.tags.each do |tag|
    proxy tag.path, "/tag.html", locals: { content: tag }, ignore: true
  end
end

configure :production do
  config[:css_dir]             = 'stylesheets'
  config[:js_dir]              = 'javascripts'
  config[:images_dir]          = 'images'
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

  page "/404.html", directory_index: false

  data.articles.each do |article|
    proxy article.path, "/article.html", locals: { content: article }, ignore: true
  end

  data.links.each do |link|
    proxy article.path, "/link.html", locals: { content: link }, ignore: true
  end

  data.pages.each do |page|
    proxy page.path, "/page.html", locals: { content: page }, ignore: true
  end

  data.tags.each do |tag|
    proxy tag.path, "/tag.html", locals: { content: tag }, ignore: true
  end
end
