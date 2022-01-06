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
      tracks = JSON.parse(response.body).dig('toptracks', 'track')
      return if tracks.blank?

      tracks.map! do |t|
        track = track(t['mbid'], t['name'], t['artist']['name'])
        next if track.blank?
        track[:play_count] = t['playcount'].to_i
        track
      end

      File.open('data/music.json','w'){ |f| f << tracks.compact.to_json }
    end

    def track(mbid, name, artist)
      track = track_by_mbid(mbid) || track_by_name_and_artist(name, artist)
      return if track.blank?

      artist = artist(track.dig('artist', 'mbid'))
      return if artist.blank?

      album = album(track.dig('album', 'mbid'))
      return if album.blank?

      track[:album] = album
      track[:artist] = artist
      track
    end

    def track_by_mbid(mbid)
      query = {
        method: 'track.getInfo',
        api_key: @api_key,
        format: 'json',
        mbid: mbid
      }

      response = HTTParty.get(@base_url, query: query)
      JSON.parse(response.body)['track']
    end

    def track_by_name_and_artist(name, artist)
      query = {
        method: 'track.getInfo',
        api_key: @api_key,
        format: 'json',
        track: name,
        artist: artist
      }
      response = HTTParty.get(@base_url, query: query)
      JSON.parse(response.body)['track']
    end

    def artist(mbid)
      query = {
        method: 'artist.getInfo',
        api_key: @api_key,
        format: 'json',
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      JSON.parse(response.body)['artist']
    end

    def album(mbid)
      query = {
        method: 'album.getInfo',
        api_key: @api_key,
        format: 'json',
        mbid: mbid
      }
      response = HTTParty.get(@base_url, query: query)
      JSON.parse(response.body)['album']
    end
  end
end
