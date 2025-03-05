class GeocodingService
    def initialize
      @geo_base_url = "https://api.openweathermap.org/geo/1.0"
      @api_key = Rails.application.config.weather_api[:api_key]
    end
    
    def geocode_address(address)
        raise StandardError, "Address cannot be blank" if address.blank?
  
        response = make_request("/direct", q: address, limit: 1)
        
        if response.success?
            parsed = response.parsed_response
            if parsed.is_a?(Array) && parsed.length > 0
                location = parsed.first
                {
                    lat: location['lat'],
                    lon: location['lon']
                }
            else
                raise StandardError, "Geocoding API Error: Invalid address or no results found"
            end
        else
            raise StandardError, "Geocoding API Error: #{response.code}"
        end
    end
    
    def geocode_zip(zip_code)
      response = make_request("/zip", zip: zip_code)
      
      if response.success?
        {
          lat: response['lat'],
          lon: response['lon'],
          zip_code: zip_code
        }
      else
        raise StandardError, "Geocoding API Error: Invalid zip code or service unavailable"
      end
    end
    
    private
    
    def make_request(endpoint, params = {})
        url = "#{@geo_base_url}#{endpoint}"
        query = params.merge(appid: @api_key)
        puts "Making request to: #{url} with params: #{query.inspect}"
        
        response = HTTParty.get(url, query: query)
        puts "Response status: #{response.code}"
        puts "Response body: #{response.body.inspect}"
        
        response
    end
  end