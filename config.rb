# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

config[:css_dir]             = 'stylesheets'
config[:js_dir]              = 'javascripts'
config[:images_dir]          = 'images'
activate :gzip
activate :dotenv
activate :autoprefixer do |config|
  config.browsers = ['last 1 version', 'last 3 safari versions', 'last 3 ios versions']
end
activate :asset_hash
activate :directory_indexes

data.articles.each do |article|
  proxy article.path, "/article.html", locals: { content: article }, ignore: true
end

data.links.each do |link|
  proxy link.path, "/link.html", locals: { content: link }, ignore: true
end

data.pages.each do |page|
  proxy page.path, "/page.html", locals: { content: page }, ignore: true
end

data.tags.each do |tag|
  proxy tag.path, "/tag.html", locals: { content: tag, title: tag.summary }, ignore: true
end

data.link_tags.each do |tag|
  proxy tag.path, "/tag.html", locals: { content: tag, title: tag.summary }, ignore: true
end

data.blog.each do |page|
  if page.current_page == 1
    proxy "/blog/index.html", "/blog.html", locals: { title: "Blog", items: page.items, current_page_number: page.current_page, next_page_number: page.next_page, previous_page_number: page.previous_page }
  else
    proxy "/blog/page/#{page.current_page}/index.html", "/blog.html", locals: { title: "Blog", items: page.items, current_page_number: page.current_page, next_page_number: page.next_page, previous_page_number: page.previous_page }
  end
end

data.link_blog.each do |page|
  if page.current_page == 1
    proxy "/links/index.html", "/blog.html", locals: { title: "Links", items: page.items, current_page_number: page.current_page, next_page_number: page.next_page, previous_page_number: page.previous_page }
  else
    proxy "/links/page/#{page.current_page}/index.html", "/blog.html", locals: { title: "Links", items: page.items, current_page_number: page.current_page, next_page_number: page.next_page, previous_page_number: page.previous_page }
  end
end

configure :development do
  activate :relative_assets
end

configure :production do
  config[:url]                 = ENV['URL']
  config[:deploy_url]          = ENV['DEPLOY_URL']
  config[:context]             = ENV['CONTEXT']
  config[:netlify]             = ENV['NETLIFY']
  activate :minify_css
  activate :minify_javascript
  activate :minify_html

  page "/404.html", directory_index: false
end
