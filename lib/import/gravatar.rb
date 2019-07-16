require 'httparty'
require 'digest/md5'

module Import
  class Gravatar
    def initialize(email:)
      @email = email
    end

    def save_avatar
      hash = Digest::MD5.hexdigest(@email)
      File.open("source/images/gravatar/#{hash}.jpg",'w'){ |f| f << HTTParty.get("https://www.gravatar.com/avatar/#{hash}?s=2048").body }
    end
  end
end
