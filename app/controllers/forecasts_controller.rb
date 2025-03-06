# app/controllers/forecasts_controller.rb
class ForecastsController < ApplicationController
  before_action :initialize_weather_data

  def index
    # Get recent locations from cookies
    @recent_locations = get_recent_locations

    fetch_weather_data if params[:address].present?
  end

  def show
    @address = params[:address] || params[:id]
    @recent_locations = get_recent_locations

    if @address.present?
      fetch_weather_data
      add_to_recent_locations(@address) if @current_weather && !@current_weather[:error]
    end
  rescue StandardError => e
    handle_error(e)
  end

  def create
    redirect_to forecast_path(address: params[:address])
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
    fetch_weather_for_coordinates(coordinates)
    add_location_details(coordinates)
    add_to_recent_locations(@address)
  rescue StandardError => e
    handle_error(e)
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
  end

  def handle_error(exception)
    flash[:error] = "Error retrieving weather data: #{exception.message}"
    redirect_to root_path
  end
end
