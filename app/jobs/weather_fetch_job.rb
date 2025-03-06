# app/jobs/weather_fetch_job.rb

class WeatherFetchJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(lat:, lon:, type: "both")
      weather_service = WeatherService.new

      case type
      when "current"
        fetch_current_weather(weather_service, lat, lon)
      when "forecast"
        fetch_forecast(weather_service, lat, lon)
      when "both"
        fetch_current_weather(weather_service, lat, lon)
        fetch_forecast(weather_service, lat, lon)
      end
    end

    private

    def fetch_current_weather(weather_service, lat, lon)
      weather_service.get_current_temperature(
        lat: lat,
        lon: lon,
        force_refresh: true
      )
    end

    def fetch_forecast(weather_service, lat, lon)
      weather_service.get_forecast(
        lat: lat,
        lon: lon,
        force_refresh: true
      )
    end
end
