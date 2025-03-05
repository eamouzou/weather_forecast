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
end