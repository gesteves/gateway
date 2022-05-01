module CustomHelpers
  require 'imgix'

  def imgix_url(key, options = {})
    client = Imgix::Client.new(domain: config[:imgix_domain], secure_url_token: config[:imgix_token], include_library_param: false).path(key)
    options[:w] = options[:widths].sort.first if options[:w].blank? && options[:widths].present?
    options.delete(:widths)
    client.to_url(options)
  end

  def imgix_srcset(key, options = {})
    srcset = []
    widths = options[:widths].sort.uniq
    options.delete(:widths)
    widths.each do |width|
      options[:w] = width
      srcset << "#{imgix_url(key, options)} #{width}w"
    end
    srcset.join(', ')
  end

  def responsive_image_tag(key, options = {})
    options[:srcset] = imgix_srcset(key, options[:imgix_options])
    options[:src] = imgix_url(key, options[:imgix_options])
    options.delete(:imgix_options)
    tag :img, options
  end

  def source_tag(key, options = {})
    options[:srcset] = imgix_srcset(key, options[:imgix_options])
    options.delete(:imgix_options)
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
end
