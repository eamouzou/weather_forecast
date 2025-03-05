class WeatherService
    def initialize
      @base_url = Rails.application.config.weather_api[:base_url]
      @api_key = Rails.application.config.weather_api[:api_key]
    end

    def get_current_temperature(lat:, lon:)
        # Call API
        HTTParty.get(
          "#{@base_url}/weather",
          query: {
            lat: lat,
            lon: lon,
            appid: @api_key,
            units: 'imperial'
          }
        )
    end
  end