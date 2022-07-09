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

  def atom_tag(url, date)
    tag = url.gsub(/^http(s)?:\/\//, '').gsub('#', '/').split('/')
    tag[0] = "tag:#{tag[0]},#{date.strftime('%Y-%m-%d')}:"
    tag.join('/')
  end
end
