# app/services/weather_service.rb

class WeatherService
  def initialize
    @base_url = Rails.application.config.weather_api[:base_url]
    @api_key = Rails.application.config.weather_api[:api_key]
  end

  def get_current_temperature(lat:, lon:, force_refresh: false)
    cache_key = "current_weather_#{lat}_#{lon}"

    begin
      # Log cache retrieval attempt
      Rails.logger.info "Attempting to retrieve current weather from cache with key: #{cache_key}"

      # Check cache unless force refresh is requested
      unless force_refresh
        cached_result = Rails.cache.read(cache_key)

        if cached_result.present?
          Rails.logger.info "Cache hit for current weather at (#{lat}, #{lon})"
          cached_result[:from_cache] = true
          return cached_result
        else
          Rails.logger.info "Cache miss for current weather at (#{lat}, #{lon})"
        end
      end

      # Fetch fresh data
      result = fetch_current_temperature(lat: lat, lon: lon)

      # Store in cache with expiration
      Rails.cache.write(cache_key, result, expires_in: 30.minutes)

      Rails.logger.info "Cached current weather for coordinates (#{lat}, #{lon})"

      result
    rescue => e
      Rails.logger.error "Error in get_current_temperature: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  def get_forecast(lat:, lon:, force_refresh: false)
    cache_key = "forecast_#{lat}_#{lon}"

    begin
      # Log cache retrieval attempt
      Rails.logger.info "Attempting to retrieve forecast from cache with key: #{cache_key}"

      # Check cache unless force refresh is requested
      unless force_refresh
        cached_result = Rails.cache.read(cache_key)

        if cached_result.present?
          Rails.logger.info "Cache hit for forecast at (#{lat}, #{lon})"
          cached_result[:from_cache] = true
          return cached_result
        else
          Rails.logger.info "Cache miss for forecast at (#{lat}, #{lon})"
        end
      end

      # Fetch fresh data
      result = fetch_forecast(lat: lat, lon: lon)

      # Store in cache with longer expiration for forecast
      Rails.cache.write(cache_key, result, expires_in: 1.hour)

      Rails.logger.info "Cached forecast for coordinates (#{lat}, #{lon})"

      result
    rescue => e
      Rails.logger.error "Error in get_forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

    private

    def fetch_with_cache(type, lat, lon)
      cache_key = "#{type}_#{lat}_#{lon}"

      # Check cache first
      cached_result = Rails.cache.read(cache_key)
      if cached_result.present?
        cached_result[:from_cache] = true
        return cached_result
      end

      # Execute the provided block to fetch fresh data
      result = yield

      # Store in cache for 30 minutes
      Rails.cache.write(cache_key, result, expires_in: 30.minutes)

      result
    end

    def fetch_current_temperature(lat:, lon:)
      response = make_api_request("weather", lat: lat, lon: lon)

      {
        temperature: response["main"]["temp"],
        feels_like: response["main"]["feels_like"],
        temp_min: response["main"]["temp_min"],
        temp_max: response["main"]["temp_max"],
        humidity: response["main"]["humidity"],
        description: response["weather"][0]["description"],
        icon: response["weather"][0]["icon"],
        wind_speed: response["wind"]["speed"],
        wind_direction: response["wind"]["deg"],
        pressure: response["main"]["pressure"],
        visibility: response["visibility"],
        sunrise: Time.at(response["sys"]["sunrise"]),
        sunset: Time.at(response["sys"]["sunset"]),
        clouds: response["clouds"]["all"],
        precipitation_chance: 0, # Base API doesn't provide this directly
        from_cache: false
      }
    end

    def fetch_forecast(lat:, lon:)
      response = make_api_request("forecast", lat: lat, lon: lon)

      {
        daily_forecast: process_forecast_data(response),
        from_cache: false
      }
    end

    def make_api_request(endpoint, lat:, lon:)
      response = HTTParty.get(
        "#{@base_url}/#{endpoint}",
        query: {
          lat: lat,
          lon: lon,
          appid: @api_key,
          units: "imperial"
        }
      )

      handle_response(response)
    end

    def handle_response(response)
      if response.success?
        response
      else
        raise "API Error: #{response.code}"
      end
    end

    def process_forecast_data(response)
      # The 5-day forecast returns data in 3-hour intervals
      forecast_list = response["list"]

      # Group by date (using the dt_txt field)
      forecast_entries_grouped_by_date = forecast_list.group_by { |entry| entry["dt_txt"].split(" ").first }

      # Process each day's data
      forecast_entries_grouped_by_date.map do |date, entries|
        {
          date: date,
          high: entries.map { |entry| entry["main"]["temp_max"] }.max,
          low: entries.map { |entry| entry["main"]["temp_min"] }.min,
          description: entries.sample["weather"][0]["description"],
          icon: entries.sample["weather"][0]["icon"],
          humidity: entries.map { |entry| entry["main"]["humidity"] }.sum / entries.size,
          wind_speed: entries.map { |entry| entry["wind"]["speed"] }.sum / entries.size,
          wind_direction: entries.map { |entry| entry["wind"]["deg"] }.sum / entries.size,
          pressure: entries.map { |entry| entry["main"]["pressure"] }.sum / entries.size,
          precipitation_chance: calculate_precipitation_chance(entries),
          clouds: entries.map { |entry| entry["clouds"]["all"] }.sum / entries.size
        }
      end
    end

    def calculate_precipitation_chance(entries)
      # Check if any entries have rain or snow
      rain_entries = entries.select { |entry| entry["rain"].present? || entry["snow"].present? }

      # Calculate probability as percentage of intervals with precipitation
      (rain_entries.length.to_f / entries.length * 100).round
    end
end
