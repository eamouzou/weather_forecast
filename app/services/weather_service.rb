# app/services/weather_service.rb

class WeatherService
  # Custom error classes
  class ApiError < StandardError; end
  class ApiUnavailableError < ApiError; end
  class InvalidRequestError < ApiError; end
  class AuthenticationError < ApiError; end
  class RateLimitError < ApiError; end

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
    rescue ApiError => e
      Rails.logger.error "API Error in get_current_temperature: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
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
    rescue ApiError => e
      Rails.logger.error "API Error in get_forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    rescue => e
      Rails.logger.error "Error in get_forecast: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  private

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
      from_cache: false,
      fetched_at: Time.now
    }
  end

  def fetch_forecast(lat:, lon:)
    response = make_api_request("forecast", lat: lat, lon: lon)

    {
      daily_forecast: process_forecast_data(response),
      from_cache: false,
      fetched_at: Time.now
    }
  end

  def make_api_request(endpoint, lat:, lon:)
    url = "#{@base_url}/#{endpoint}"
    query_params = {
      lat: lat,
      lon: lon,
      appid: @api_key,
      units: "imperial"
    }

    Rails.logger.info "Making API request to: #{url} with coordinates: (#{lat}, #{lon})"

    response = HTTParty.get(url, query: query_params)

    handle_response(response)
  rescue Timeout::Error, Errno::ECONNREFUSED => e
    raise ApiUnavailableError, "Weather API is currently unavailable: #{e.message}"
  end

  def handle_response(response)
    if response.success?
      response
    else
      code = response.code
      message = response.parsed_response.is_a?(Hash) ? response.parsed_response["message"] : nil

      case code
      when 401, 403
        raise AuthenticationError, "API Authentication Error: #{message || code}"
      when 404
        raise InvalidRequestError, "API Invalid Request: #{message || code}"
      when 429
        raise RateLimitError, "API Rate Limit Exceeded: #{message || code}"
      when 500..599
        raise ApiUnavailableError, "API Unavailable: #{message || code}"
      else
        raise ApiError, "API Error: #{code} - #{message || 'Unknown error'}"
      end
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
