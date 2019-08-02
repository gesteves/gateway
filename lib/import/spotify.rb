require 'redis'

module Import
  class Spotify
    def initialize
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      refresh_token = @redis.get('spotify:refresh_token:v2') || ENV['SPOTIFY_REFRESH_TOKEN']
      @access_token = get_access_token(refresh_token: refresh_token)
    end

    def recent_albums
      track_ids = recent_tracks.map { |i| i['track']['id'] }
      albums = album_data(track_ids: track_ids)
      File.open('data/albums.json','w'){ |f| f << albums.to_json }
    end

    def top_albums
      tracks = []
      ['short_term', 'medium_term', 'long_term'].each do |r|
        tracks = top_tracks(time_range: r)
        break unless tracks.empty?
      end
      track_ids = tracks.map { |i| i['id'] }
      albums = album_data(track_ids: track_ids, sort_by_popularity: true)
      File.open('data/albums.json','w'){ |f| f << albums.to_json }
    end

    def top_tracks(time_range:)
      url = "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=#{time_range}"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      tracks = []
      if response.code == 200
        tracks = JSON.parse(response.body)['items']
      end
      tracks
    end

    def recent_tracks
      url = "https://api.spotify.com/v1/me/player/recently-played?limit=50"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      tracks = []
      if response.code == 200
        tracks = JSON.parse(response.body)['items']
      end
      tracks
    end

    def album_data(track_ids:, sort_by_popularity: false)
      url = "https://api.spotify.com/v1/tracks?ids=#{track_ids.join(',')}"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      items = []
      if response.code == 200
        items = JSON.parse(response.body)['tracks']
        items = items.map { |i| i['album'] }.group_by { |i| i['id'] }.values
        items = items.sort { |a, b| b.size <=> a.size } if sort_by_popularity
        items = items.map(&:first).map { |album| format_album(data: album) }
      end
      items
    end

    def format_album(data:)
      {
        id: data['id'],
        name: unclutter_album_name(name: data['name']),
        url: data['external_urls']['spotify'],
        artists: data['artists'].map { |a| format_artist(artist: a) },
        image_url: data['images'][0]['url'],
        release_date: data['release_date'],
        release_date_precision: data['release_date_precision'],
        genres: data['genres']
      }.compact
    end

    def format_artist(artist:)
      {
        id: artist['id'],
        name: artist['name'],
        url: artist['external_urls']['spotify']
      }
    end

    # Remove shit like [remastered] and (deluxe version) or whatever from album names
    def unclutter_album_name(name:)
      name.gsub(/\[[\w\s]+\]/,'').strip.gsub(/\([\w\s-]+\)$/,'').strip
    end

    def get_access_token(refresh_token:)
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
