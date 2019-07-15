require 'redis'

module Import
  class Spotify
    def initialize(refresh_token)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      refresh_token = @redis.get('spotify:refresh_token:v2') || ENV['SPOTIFY_REFRESH_TOKEN']
      @access_token = get_access_token(refresh_token)
    end

    def recent_albums
      track_ids = recent_tracks.map { |i| i['track']['id'] }
      albums = album_data(track_ids)
      File.open('data/spotify.json','w'){ |f| f << albums.to_json }
    end

    def recent_tracks
      url = "https://api.spotify.com/v1/me/player/recently-played?limit=50"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      items = []
      if response.code == 200
        items = JSON.parse(response.body)['items']
      end
      items
    end

    def album_data(ids)
      url = "https://api.spotify.com/v1/tracks?ids=#{ids.join(',')}"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      items = []
      if response.code == 200
        items = JSON.parse(response.body)['tracks']
        items = items.map { |i| i['album'] }
                  .group_by { |i| i['id'] }
                  .values
                  .map { |album| format_album album[0] }
      end
      items
    end

    def format_album(data)
      album = {
        id: data['id'],
        name: unclutter_album_name(data['name']),
        url: data['external_urls']['spotify'],
        artists: data['artists'].map { |a| format_artist(a) },
        image_url: data['images'][0]['url'],
        release_date: data['release_date'],
        release_date_precision: data['release_date_precision'],
        genres: data['genres']
      }.compact
      File.open("source/images/spotify/#{album[:id]}.jpg",'w'){ |f| f << HTTParty.get(album[:image_url]).body }
      album
    end

    def format_artist(artist)
      {
        id: artist['id'],
        name: artist['name'],
        url: artist['external_urls']['spotify']
      }
    end

    # Remove shit like [remastered] and (deluxe version) or whatever from album names
    def unclutter_album_name(album)
      album.gsub(/\[[\w\s]+\]/,'').strip.gsub(/\([\w\s-]+\)$/,'').strip
    end

    def get_access_token(refresh_token)
      body = {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        redirect_uri: ENV['SITE_URL'],
        client_id: ENV['SPOTIFY_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLIENT_SECRET']
      }
      response = HTTParty.post('https://accounts.spotify.com/api/token', body: body)
      if response.code ==  200
        response_body = JSON.parse(response.body)
        @redis.set('spotify:refresh_token', response_body['refresh_token']) unless response_body['refresh_token'].nil?
        access_token = response_body['access_token']
      else
        access_token = nil
      end
      access_token
    end
  end
end
