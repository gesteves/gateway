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
        limit: @count
      }
      response = HTTParty.get(@base_url, query: query)
      return if response.code >= 400

      tracks = JSON.parse(response.body).dig('toptracks', 'track')&.map do |t|
        track = track(t['name'], t['artist']['name'])
        track[:play_count] = t['playcount'].to_i
        track
      end

      File.open('data/music.json','w'){ |f| f << tracks.compact.to_json }
    end

    def track(track, artist)
      query = {
        method: 'track.getInfo',
        api_key: @api_key,
        format: 'json',
        track: track,
        artist: artist
      }
      response = HTTParty.get(@base_url, query: query)
      return if response.code >= 400

      track = JSON.parse(response.body)['track']
      artist = artist(track.dig('artist', 'mbid'))
      return if artist.blank?
      album = album(track.dig('album', 'mbid'))
      return if album.blank?

      track[:album] = album
      track[:artist] = artist
      track
    end

    def artist(mbid)
      return if mbid.blank?
      query = {
        method: 'artist.getInfo',
        api_key: @api_key,
        format: 'json',
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      return if response.code >= 400

      JSON.parse(response.body)['artist']
    end

    def album(mbid)
      return if mbid.blank?
      query = {
        method: 'album.getInfo',
        api_key: @api_key,
        format: 'json',
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      return if response.code >= 400

      JSON.parse(response.body)['album']
    end
  end
end
