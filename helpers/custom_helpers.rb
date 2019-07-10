module CustomHelpers
  require 'imgix'
  require 'digest/md5'

  def imgix_url(url, options)
    opts = { auto: 'format,compress', square: false }.merge(options)
    if opts[:square]
      opts[:fit] = 'crop'
      opts[:h] = opts[:w]
      opts.delete(:square)
    end
    url = "#{ENV['DEPLOY_URL']}#{url}" unless ENV['DEPLOY_URL'].nil?
    client = Imgix::Client.new(host: config[:imgix_domain], secure_url_token: config[:imgix_token], include_library_param: false).path(url)
    client.to_url(opts)
  end

  def srcset(url, sizes, opts = {})
    srcset = []
    sizes.each do |size|
      opts[:w] = size
      srcset << "#{imgix_url(url, opts)} #{size}w"
    end
    srcset.join(', ')
  end

  def gravatar_hash(email)
    Digest::MD5.hexdigest(email)
  end

  def responsive_image_tag(source_url, attributes)
    attrs = { square: false, widths: [150], loading: 'lazy' }.merge(attributes)
    square = attrs[:square]
    widths = attrs[:widths].sort.uniq
    attrs[:intrinsicsize] = '1x1' if square
    if config[:environment].to_s == 'production'
      attrs[:srcset] = srcset(source_url, widths, square: square)
      attrs[:src] = imgix_url(source_url, w: widths.first, square: square)
    else
      attrs[:srcset] = widths.map { |s| "https://www.fillmurray.com/#{s}/#{s} #{s}w" }.join(', ')
      attrs[:src] = "https://www.fillmurray.com/#{widths.first}/#{widths.first}"
    end
    attrs.delete(:square)
    attrs.delete(:widths)
    content_tag :img, nil, attrs
  end

end
