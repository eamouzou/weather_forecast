# app/controllers/forecasts_controller.rb

class ForecastsController < ApplicationController
  before_action :initialize_weather_data

  def index
    @recent_locations = get_recent_locations
    fetch_weather_data if params[:address].present?
  end

  def show
    @address = params[:address] || params[:id]
    @recent_locations = get_recent_locations

    if @address.present?
      begin
        fetch_weather_data
        add_to_recent_locations(@address) if @current_weather && !@current_weather[:error]

        # Schedule background refresh if we have valid weather data
        if @current_weather && @forecast
          coordinates = get_coordinates(@address)
          # Simply pass the parameters directly
          WeatherFetchJob.perform_async(
            coordinates[:lat],
            coordinates[:lon],
            "both"
          )
          Rails.logger.info "Scheduled background refresh for (#{coordinates[:lat]}, #{coordinates[:lon]})"
        end
      rescue StandardError => e
        return handle_error(e)
      end
    end
  end

  def create
    redirect_to forecast_path(address: params[:address])
  end

  def test_redis
    cache_key = "test_key_#{Time.now.to_i}"
    cache_value = "Test value: #{Time.now}"

    Rails.cache.write(cache_key, cache_value, expires_in: 1.minute)
    @cached_value = Rails.cache.read(cache_key)

    # Test direct Redis access
    with_redis do |redis|
      redis.set("direct_test_key", "Direct Redis test: #{Time.now}")
      @direct_value = redis.get("direct_test_key")
    end

    render plain: "Cache Test: #{@cached_value}\nDirect Test: #{@direct_value}"
  end

  private

  def initialize_weather_data
    @current_weather = default_current_weather
    @forecast = default_forecast
    @location = { address: nil }
  end

  def default_current_weather
    {
      temperature: nil,
      feels_like: nil,
      temp_min: nil,
      temp_max: nil,
      humidity: nil,
      description: "No data available",
      from_cache: false
    }
  end

  def default_forecast
    {
      daily_forecast: [],
      from_cache: false
    }
  end

  def fetch_weather_data
    @location[:address] = @address

    coordinates = get_coordinates(@address)
    weather_service = WeatherService.new

    # Attempt to fetch from cache first
    @current_weather = weather_service.get_current_temperature(
      lat: coordinates[:lat],
      lon: coordinates[:lon]
    ) || default_current_weather

    @forecast = weather_service.get_forecast(
      lat: coordinates[:lat],
      lon: coordinates[:lon]
    ) || default_forecast

    # Add location details
    add_location_details(coordinates)
    add_to_recent_locations(@address)
  rescue StandardError => e
    # Return the result of handle_error to stop execution
    return handle_error(e)
  end

  def get_recent_locations
    return [] unless cookies[:recent_locations]

    begin
      JSON.parse(cookies[:recent_locations]) || []
    rescue
      []
    end
  end

  def add_to_recent_locations(address)
    return if address.blank?

    recent = get_recent_locations

    # Remove the location if it already exists (to move it to the front)
    recent.delete(address)

    # Add to the beginning of the array
    recent.unshift(address)

    # Keep only the last 5 locations
    recent = recent.take(5)

    # Store in cookies for 3 months
    cookies[:recent_locations] = {
      value: recent.to_json,
      expires: 3.months.from_now
    }

    # Update the instance variable
    @recent_locations = recent
  end

  def get_coordinates(address)
    AddressParser.new.parse(address)
  end

  def fetch_weather_for_coordinates(coordinates)
    weather_service = WeatherService.new
    @current_weather = weather_service.get_current_temperature(
      lat: coordinates[:lat],
      lon: coordinates[:lon]
    )

    @forecast = weather_service.get_forecast(
      lat: coordinates[:lat],
      lon: coordinates[:lon]
    )
  end

  def add_location_details(coordinates)
    @location[:zip_code] = coordinates[:zip_code] if coordinates[:zip_code]
    # Store coordinates for background job use
    @location[:lat] = coordinates[:lat]
    @location[:lon] = coordinates[:lon]
  end

  def handle_error(exception)
    flash[:error] = "Error retrieving weather data: #{exception.message}"
    redirect_to root_path
  end
end
