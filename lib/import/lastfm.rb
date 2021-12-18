require 'httparty'
require 'active_support/all'

 module Import
   class Lastfm
    def initialize(api_key:, user:, count:)
      @api_key = api_key
      @count = count
      @user = user
      @base_url = 'http://ws.audioscrobbler.com/2.0/'
    end

    def top_tracks
      query = {
        method: 'user.gettoptracks',
        user: @user,
        api_key: @api_key,
        format: 'json',
        period: '7day',
        limit: @count * 2
      }
      response = HTTParty.get(@base_url, query: query)
      return nil if response.code >= 400
      tracks = JSON.parse(response.body)['toptracks']['track'].map { |t| track(t['name'], t['artist']['name'], t['playcount'].to_i) }.compact.slice(0, @count)
      File.open('data/music.json','w'){ |f| f << tracks.to_json }
    end

    def track(track, artist, playcount)
      puts "Fetching track #{track} by #{artist}"
      query = {
        method: 'track.getInfo',
        api_key: @api_key,
        format: 'json',
        username: @user,
        track: track,
        artist: artist
      }
      response = HTTParty.get(@base_url, query: query)
      return nil if response.code >= 400
      track = JSON.parse(response.body)['track']
      artist = artist(track.dig('artist', 'mbid'))
      album = album(track.dig('album', 'mbid'))
      return nil if album.blank? || artist.blank?
      {
        id: track['mbid'],
        name: track['name'],
        url: track['url'],
        play_count: playcount,
        artist: artist,
        album: album
      }.compact
    end

    def artist(mbid)
      return if mbid.blank?
      query = {
        method: 'artist.getInfo',
        api_key: @api_key,
        format: 'json',
        username: @user,
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      return nil if response.code >= 400
      artist = JSON.parse(response.body)['artist']
      {
        id: artist['mbid'],
        name: artist['name'],
        url: artist['url']
      }.compact
    end

    def album(mbid)
      return if mbid.blank?
      query = {
        method: 'album.getInfo',
        api_key: @api_key,
        format: 'json',
        username: @user,
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      return nil if response.code >= 400
      album = JSON.parse(response.body)['album']
      {
        id: album['mbid'],
        name: album['name'],
        url: album['url'],
        image_url: album['image'].last['#text']
      }.compact
    end
  end
end
