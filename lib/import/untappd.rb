require 'httparty'

module Import
  class Untappd
    def initialize(username, client_id, client_secret, count)
      @username = username
      @client_id = client_id
      @client_secret = client_secret
      @count = count
    end

    def get_beers
      checkins = JSON.parse(HTTParty.get("https://api.untappd.com/v4/user/info/#{@username}?client_id=#{@client_id}&client_secret=#{@client_secret}").body)['response']['user']['checkins']['items'].uniq{ |b| b['beer']['bid'] }.slice(0, @count)
      beers = []
      checkins.each do |checkin|
        beer = {
          beer_id: checkin['beer']['bid'],
          beer_name: checkin['beer']['beer_name'],
          brewery_name: checkin['brewery']['brewery_name'],
          beer_url: "https://untappd.com/beer/#{checkin['beer']['bid']}",
          brewery_url: "https://untappd.com#{checkin['brewery']['brewery_page_url']}",
          beer_style: checkin['beer']['beer_style']
        }
        beers << beer
      end
      File.open('data/untappd.json','w'){ |f| f << beers.to_json }
    end
  end
end
