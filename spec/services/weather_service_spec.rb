# spec/services/weather_service_spec.rb
require 'rails_helper'

RSpec.describe WeatherService do
    describe '#get_current_temperature' do
        it 'fetches current temperature for given coordinates' do
            VCR.use_cassette('openweathermap/current_weather') do
                service = WeatherService.new
                result = service.get_current_temperature(lat: 40.7128, lon: -74.0060)

                # Verify result is a hash
                expect(result).to be_a(Hash)

                # Verify temperature data is within reasonable range
                expect(result).to have_key(:temperature)
                expect(result[:temperature]).to be_a(Numeric)
                expect(result[:temperature]).to be_between(0, 150)

                # Verify cache status
                expect(result).to have_key(:from_cache)
                expect(result[:from_cache]).to be(false)
            end
        end
    end


    describe '#get_forecast' do
        it 'fetches extended forecast for given coordinates' do
            VCR.use_cassette('openweathermap/forecast') do
                service = WeatherService.new
                result = service.get_forecast(lat: 40.7128, lon: -74.0060)

                # Verify result structure
                expect(result).to be_a(Hash)
                expect(result).to have_key(:daily_forecast)
                expect(result[:daily_forecast]).to be_an(Array)
                expect(result[:daily_forecast].length).to be > 0

                # Verify forecast structure
                first_day = result[:daily_forecast].first
                expect(first_day).to have_key(:date)
                expect(first_day).to have_key(:high)
                expect(first_day).to have_key(:low)
                expect(first_day[:high]).to be_a(Numeric)
                expect(first_day[:low]).to be_a(Numeric)
                expect(first_day[:high]).to be >= first_day[:low]

                # Verify cache status
                expect(result).to have_key(:from_cache)
                expect(result[:from_cache]).to be(false)
            end
        end
    end

    describe 'caching' do
        it 'returns cached results for the same coordinates' do
            service = WeatherService.new

            # Mock the API response
            mock_weather_data = {
                'main' => { 'temp' => 72.5, 'feels_like' => 70.1, 'temp_min' => 68.0, 'temp_max' => 75.0, 'humidity' => 65 },
                'weather' => [ { 'description' => 'partly cloudy' } ]
            }

            # First call - simulate API request
            allow(service).to receive(:make_api_request).once.and_return(mock_weather_data)
            allow(Rails.cache).to receive(:read).and_return(nil)
            allow(Rails.cache).to receive(:write)

            first_result = service.get_current_temperature(lat: 40.7128, lon: -74.0060)
            expect(first_result[:from_cache]).to be(false)

            # Second call - should use cache
            allow(Rails.cache).to receive(:read).and_return(first_result)
            second_result = service.get_current_temperature(lat: 40.7128, lon: -74.0060)

            expect(second_result[:from_cache]).to be(true)
            expect(second_result[:temperature]).to eq(72.5)
        end

        it 'respects the cache expiration time' do
            service = WeatherService.new

            allow(service).to receive(:make_api_request).and_return(
                { 'main' => { 'temp' => 72.5 }, 'weather' => [ { 'description' => 'clear' } ] }
            )
            allow(Rails.cache).to receive(:read).and_return(nil)
            allow(Rails.cache).to receive(:write)

            service.get_current_temperature(lat: 40.7128, lon: -74.0060)

            expect(Rails.cache).to have_received(:write).with(
                "weather_40.7128_-74.006",
                anything,
                expires_in: 30.minutes
            )
        end
    end
end
