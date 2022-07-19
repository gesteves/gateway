require 'redcarpet'
require 'nokogiri'

module CustomHelpers
  def full_url(resource)
    domain = if config[:netlify] && config[:context] == 'production'
      config[:url]
    elsif config[:netlify] && config[:context] != 'production'
      config[:deploy_url]
    else
      'http://localhost:4567'
    end
    "#{domain}#{url_for(resource)}"
  end

  def remove_widows(text)
    return if text.blank?
    words = text.split(/\s+/)
    return text if words.size == 1
    last_words = words.pop(2).join('&nbsp;')
    words.append(last_words).join(' ')
  end

  def atom_tag(url, date = nil)
    tag = url.gsub(/^http(s)?:\/\//, '').gsub('#', '/').split('/')
    tag[0] = "tag:#{tag[0]},#{date.strftime('%Y-%m-%d')}:"
    tag.join('/')
  end

  def page_title(title: '', separator: ' · ')
    [title, data.home.title].reject(&:blank?).uniq.join(separator)
  end

  def hide_from_search_engines?(content)
    return true if content.draft
    !content.indexInSearchEngines
  end

  def markdown_to_html(text)
    return if text.blank?
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true, disable_indented_code_blocks: true)
    Redcarpet::Render::SmartyPants.render(markdown.render(text))
  end

  def markdown_to_text(text)
    strip_tags(markdown_to_html(text))
  end

  def source_tag(url, options = {})
    srcset_opts = { fm: options[:format] }.compact
    options[:srcset] = srcset(url: url, widths: options[:widths], options: srcset_opts)
    options.delete(:widths)
    options.delete(:format)
    tag :source, options
  end

  def srcset(url:, widths:, options: {})
    url = URI.parse(url)
    srcset = widths.map do |w|
      query = options.merge!({ w: w })
      url.query = URI.encode_www_form(query)
      "#{url.to_s} #{w}w"
    end
    srcset.join(', ')
  end

  def content_summary(content)
    return content.summary if content.summary.present?
    truncate(markdown_to_text(content.body), length: 10)
  end

  def get_asset_dimensions(asset_id)
    asset = data.assets.find { |a| a.sys.id == asset_id }
    return asset&.width, asset&.height
  end

  def get_asset_description(asset_id)
    asset = data.assets.find { |a| a.sys.id == asset_id }
    asset&.description&.strip
  end

  def get_asset_id(url)
    url.split('/')[4]
  end

  def responsivize_images(html, widths: [100, 200, 300], sizes: '100vw', formats: ['avif', 'webp', 'jpg'])
    return if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('img').each do |img|
      # Set the width & height of the image,
      # and make it lazy-load.
      asset_id = get_asset_id(img['src'])
      width, height = get_asset_dimensions(asset_id)
      img['loading'] = 'lazy'
      if width.present? && height.present?
        img['width'] = width
        img['height'] = height
      end
      # Then wrap it in a picture element.
      img.wrap('<picture></picture>')

      # Add a source element for each image format,
      # as a sibling of the img element in the picture tag.
      formats.each do |format|
        img.add_previous_sibling(source_tag(img['src'], sizes: sizes, type: "image/#{format}", format: format, widths: widths))
      end
    end
    doc.to_html
  end

  def set_alt_text(html)
    return if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('img').each do |img|
      asset_id = get_asset_id(img['src'])
      alt_text = get_asset_description(asset_id)
      img['alt'] = alt_text if alt_text.present?
    end
    doc.to_html
  end

  def add_figure_elements(html)
    return if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('img').each do |img|
      # Get the parent of the image
      parent = img.parent
      # Remove the image
      img = img.remove
      # The caption is whatever is left in the parent, so store it...
      caption = parent.inner_html
      # ...then put the image back
      parent.prepend_child(img)
      # Wrap the whole thing in a figure element,
      # with the caption in a figcaption, if present,
      # then replace the original paragraph with it.
      img.wrap('<figure></figure>')
      img.add_next_sibling("<figcaption>#{caption}</figcaption>") if caption.present?
      parent.replace(img.parent)
    end
    doc.to_html
  end

  def set_code_language(html)
    return if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('code').each do |code|
      code['class'] = "language-#{code['class']}" if code['class'].present?
    end
    doc.to_html
  end

  def render_body(text)
    set_code_language(set_alt_text(responsivize_images(add_figure_elements(markdown_to_html(text)), widths: data.srcsets.entry.widths, sizes: data.srcsets.entry.sizes.join(', '), formats: data.srcsets.entry.formats)))
  end
end
