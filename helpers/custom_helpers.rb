module CustomHelpers
  require "imgix"

  def imgix_url(url, options)
    opts = { auto: 'format' }.merge(options)
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

end