module Import
  class Lastfm
    def initialize(api_key, username)
      @api_key = api_key
      @username = username
    end

    def get_albums
      albums = []
      %w[7day 1month 3month 6month 12month overall].each do |period|
        albums = get_top_albums(period)
        break unless albums.empty?
      end
      File.open('data/lastfm.json','w'){ |f| f << albums.to_json }
    end

    def get_top_albums(period)
      url = "http://ws.audioscrobbler.com/2.0/?method=user.gettopalbums&user=#{@username}&api_key=#{@api_key}&format=json&period=#{period}&limit=5"
      response = HTTParty.get(url)
      return nil if response.code != 200
      JSON.parse(response.body).dig('topalbums', 'album')&.map { |a| format_album(a) }
    end

    def format_album(data)
      album = {
        id: data['@attr']['rank'],
        name: unclutter_album_name(data['name']),
        url: data['url'],
        artist: {
          name: data['artist']['name'],
          url: data['artist']['url']
        },
        image_url: data['image'].last['#text']
      }
      File.open("source/images/lastfm/#{album[:id]}.jpg",'w'){ |f| f << HTTParty.get(album[:image_url]).body }
      album
    end

    # Remove shit like [remastered] and (deluxe version) or whatever from album names
    def unclutter_album_name(album)
      album.gsub(/\[[\w\s]+\]/,'').strip.gsub(/\([\w\s-]+\)$/,'').strip
    end
  end
end
