# app/controllers/forecasts_controller.rb
class ForecastsController < ApplicationController
  before_action :initialize_weather_data

  def index
    fetch_weather_data if params[:address].present?
  end

  def show
    @address = params[:address] || params[:id]
    fetch_weather_data if @address.present?
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
  rescue StandardError => e
    handle_error(e)
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
