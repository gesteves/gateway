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
      data['data'][0, @count].each do |e|
        photo = e['relationships']['photos']['data'][0]
        File.open("source/images/denali/#{photo['id']}.jpg",'w'){ |f| f << HTTParty.get(photo['links']['square_944']).body }
      end
      File.open('data/denali.json','w'){ |f| f << data.to_json }
    end
  end
end
