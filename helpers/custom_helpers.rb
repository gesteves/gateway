module CustomHelpers
  require 'imgix'
  require 'digest/md5'

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

  def denali_image_tag(photo)
    caption = photo.attributes.caption.nil? ? "Latest from my photoblog" : photo.attributes.caption
    photo_url = image_path "denali/#{photo.id}.jpg"
    sizes_array = [252, 307, 461, 519, 340, 274, 206, 412].sort.uniq
    srcset = srcset(photo_url, sizes_array)
    src = imgix_url(photo_url, { w: sizes_array.first })
    sizes = "(min-width: 1440px) 206px, (min-width: 1024px) calc((((200vw/3) - 6rem)/4) - 10px), (min-width: 768px) calc(((100vw - 3rem)/4) - 10px), calc(((100vw - 3rem)/2) - 10px)"
    content_tag 'img', nil, intrinsicsize: "#{sizes_array.first}x#{sizes_array.first}", src: src, srcset: srcset, sizes: sizes, alt: caption
  end

  def gravatar_image_tag(email)
    hash = Digest::MD5.hexdigest(email)
    path = "source/images/gravatar/#{hash}.jpg"
    content_tag :img, nil, intrinsicsize: '150x150', src: imgix_url(image_path(path), w: 150), srcset: srcset(image_path(path), [75, 150, 225, 300, 450]), sizes: "(min-width: 1024px) 150px, 75px", class: 'avatar'
  end

end
