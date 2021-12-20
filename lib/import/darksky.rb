require 'httparty'
require 'active_support/all'

 module Import
   class Darksky
    def initialize(api_key:, maps_api_key:, location:)
      @api_key = api_key
      @maps_api_key = maps_api_key
      @location = location
    end

    def weather
      lat, long = reverse_geocode(@location)
      return if lat.blank? || long.blank?
      response = HTTParty.get("https://api.darksky.net/forecast/#{@api_key}/#{lat},#{long}").body
      File.open('data/weather.json','w'){ |f| f << response }
    end

    def reverse_geocode(location)
      response = HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(location)}&key=#{@maps_api_key}").body
      data = JSON.parse(response)
      lat = data.dig('results', 0, 'geometry', 'location', 'lat')
      long = data.dig('results', 0, 'geometry', 'location', 'lng')
      return lat, long
    end
  end
end
