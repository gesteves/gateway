require 'redcarpet'
require 'nokogiri'

module CustomHelpers
  def source_tag(url, options = {})
    src = URI.parse(url)
    srcset = options[:widths].map do |w|
      query = { w: w, fm: options[:format] }
      src.query = URI.encode_www_form(query)
      "#{src.to_s} #{w}w"
    end
    options[:srcset] = srcset.join(', ')
    options.delete(:widths)
    options.delete(:format)
    tag :source, options
  end

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

  def noindex_content?(content)
    content.draft || (!content.draft && !content.indexInSearchEngines)
  end

  def markdown_to_html(text)
    return if text.blank?
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    Redcarpet::Render::SmartyPants.render(markdown.render(text))
  end

  def srcset(url:, widths:, options: {})
    srcset = widths.map do |w|
      query = options.merge!({ w: w })
      url.query = URI.encode_www_form(query)
      "#{url.to_s} #{w}w"
    end
    srcset.join(', ')
  end

  def responsivize_images(html, widths: [100, 200, 300], sizes: '100vw', formats: ['avif', 'webp', 'jpg'])
    return if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('img').each do |img|
      # Parse the URL of the image, we'll need it later.
      src = URI.parse(img['src'])

      # Add srcset/sizes to the base img, and make it lazy load.
      img['sizes'] = sizes
      img['srcset'] = srcset(url: src, widths: widths)
      img['loading'] = 'lazy'

      # Then wrap it in a picture element.
      img.wrap('<picture></picture>')

      # Add a source element for each image format,
      # as a sibling of the img element in the picture tag.
      formats.each do |format|
        srcset = srcset(url: src, widths: widths, options: { fm: format })
        img.add_previous_sibling("<source srcset=\"#{srcset}\" sizes=\"#{sizes}\" type=\"image/#{format}\">")
      end
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
end
