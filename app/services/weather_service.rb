class WeatherService
    def initialize
      @base_url = Rails.application.config.weather_api[:base_url]
      @api_key = Rails.application.config.weather_api[:api_key]
    end
  end