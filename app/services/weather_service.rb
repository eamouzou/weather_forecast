class WeatherService
    def initialize
        @base_url = Rails.application.config.weather_api[:base_url]
        @api_key = Rails.application.config.weather_api[:api_key]
    end

    def get_current_temperature(lat:, lon:)
        response = make_api_request("weather", lat: lat, lon: lon)
        
        {
            temperature: response['main']['temp'],
            from_cache: false
        }
    end      
      
    private
      
    def make_api_request(endpoint, lat:, lon:)
        response = HTTParty.get(
            "#{@base_url}/#{endpoint}",
            query: {
                lat: lat,
                lon: lon,
                appid: @api_key,
                units: 'imperial'
            }
        )
        
        handle_response(response)
    end
    
    def handle_response(response)
        if response.success?
            response
        else
            raise "API Error: #{response.code} - #{response.message}"
        end
    end
  end