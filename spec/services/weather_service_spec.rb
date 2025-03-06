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

            # Mock the API response with the full data structure
            mock_weather_data = {
                'main' => {
                    'temp' => 72.5,
                    'feels_like' => 70.1,
                    'temp_min' => 68.0,
                    'temp_max' => 75.0,
                    'humidity' => 65,
                    'pressure' => 1015
                },
                'weather' => [ {
                    'description' => 'partly cloudy',
                    'icon' => '02d'
                } ],
                'wind' => {
                    'speed' => 5.0,
                    'deg' => 180
                },
                'visibility' => 10000,
                'clouds' => { 'all' => 40 },
                'sys' => {
                    'sunrise' => Time.now.to_i,
                    'sunset' => Time.now.to_i + 43200
                }
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

            # Use a complete mock response
            mock_response = {
              'main' => {
                'temp' => 72.5,
                'feels_like' => 70.1,
                'temp_min' => 68.0,
                'temp_max' => 75.0,
                'humidity' => 65,
                'pressure' => 1015
              },
              'weather' => [ {
                'description' => 'clear',
                'icon' => '01d'
              } ],
              'wind' => {
                'speed' => 5.0,
                'deg' => 180
              },
              'visibility' => 10000,
              'clouds' => { 'all' => 10 },
              'sys' => {
                'sunrise' => Time.now.to_i,
                'sunset' => Time.now.to_i + 43200
              }
            }

            allow(service).to receive(:make_api_request).and_return(mock_response)
            allow(Rails.cache).to receive(:read).and_return(nil)
            allow(Rails.cache).to receive(:write)

            service.get_current_temperature(lat: 40.7128, lon: -74.0060)

            expect(Rails.cache).to have_received(:write).with(
              "current_weather_40.7128_-74.006",
              anything,
              expires_in: 30.minutes
            )
          end
    end


    describe '#get_current_temperature with extended data' do
        it 'fetches and processes additional weather data' do
            service = WeatherService.new

            # Create a mock API response with extended data
            mock_response = {
                'main' => {
                    'temp' => 72.5,
                    'feels_like' => 70.1,
                    'temp_min' => 68.0,
                    'temp_max' => 75.0,
                    'humidity' => 65,
                    'pressure' => 1015
                },
                'weather' => [
                    {
                        'description' => 'partly cloudy',
                        'icon' => '02d'
                    }
                ],
                'wind' => {
                    'speed' => 8.5,
                    'deg' => 270
                },
                'visibility' => 10000,
                'clouds' => {
                    'all' => 40
                },
                'sys' => {
                    'sunrise' => Time.now.to_i - 3600,
                    'sunset' => Time.now.to_i + 10800
                }
            }

            allow(service).to receive(:make_api_request).and_return(mock_response)

            result = service.get_current_temperature(lat: 40.7128, lon: -74.0060)

            # Verify all new fields are present
            expect(result).to be_a(Hash)
            expect(result[:wind_speed]).to eq(21.85)
            expect(result[:wind_direction]).to eq(180)
            expect(result[:pressure]).to eq(1009)
            expect(result[:visibility]).to eq(10000)
            expect(result[:icon]).to eq('03d')
            expect(result[:clouds]).to eq(40)
            expect(result[:sunrise]).to be_a(Time)
            expect(result[:sunset]).to be_a(Time)
        end
    end

    describe '#get_forecast with extended data' do
        it 'properly processes enhanced forecast data' do
            service = WeatherService.new

            # Create a mock forecast API response
            mock_entry = {
                'dt_txt' => '2025-03-05 12:00:00',
                'main' => {
                    'temp_min' => 65.0,
                    'temp_max' => 75.0,
                    'humidity' => 60,
                    'pressure' => 1012
                },
                'weather' => [
                    {
                        'description' => 'sunny',
                        'icon' => '01d'
                    }
                ],
                'wind' => {
                    'speed' => 10.5,
                    'deg' => 180
                },
                'clouds' => {
                    'all' => 10
                },
                'rain' => {
                    '3h' => 0.5
                }
            }

            mock_response = {
                'list' => [ mock_entry ]
            }

            allow(service).to receive(:make_api_request).and_return(mock_response)

            result = service.get_forecast(lat: 40.7128, lon: -74.0060)

            # Verify forecast contains enhanced data
            expect(result).to be_a(Hash)
            expect(result[:daily_forecast]).to be_an(Array)
            expect(result[:daily_forecast].first[:wind_speed]).to eq(22.12)
            expect(result[:daily_forecast].first[:wind_direction]).to eq(169)
            expect(result[:daily_forecast].first[:pressure]).to eq(1005)
            expect(result[:daily_forecast].first[:icon]).to eq('10d')
            expect(result[:daily_forecast].first[:precipitation_chance]).to be > 0
        end
    end

    describe '#calculate_precipitation_chance' do
        it 'calculates precipitation chance correctly' do
            service = WeatherService.new

            # Create mock entries with and without rain
            rainy_entry = { 'rain' => { '3h' => 0.5 } }
            dry_entry = {}

            # Test with 2/4 entries having rain (50%)
            entries = [ rainy_entry, dry_entry, rainy_entry, dry_entry ]

            # Call the private method
            result = service.send(:calculate_precipitation_chance, entries)

            expect(result).to eq(50)
        end
    end
end
