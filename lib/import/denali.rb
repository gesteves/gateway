require 'httparty'

module Import
  class Denali
    def initialize(url, count = 12)
      @url = url
      @count = count
    end

    def get_photos
      response = HTTParty.get(@url, headers: { 'Content-Type' => 'application/vnd.api+json' })
      data = JSON.parse(response.body)
      data['data'] = data['data'][0, @count]
      entries = []
      data['data'].each do |e|
        entry = {
          id: e['id'],
          title: e['attributes']['plain_title'],
          caption: e['relationships']['photos']['data'][0]['attributes']['plain_caption'],
          photo_url: e['relationships']['photos']['data'][0]['links']['square_944'],
          url: e['links']['self']
        }
        File.open("source/images/denali/#{entry[:id]}.jpg",'w'){ |f| f << HTTParty.get(entry[:photo_url]).body }
        entries << entry
      end
      File.open('data/denali.json','w'){ |f| f << entries.to_json }
    end
  end
end
