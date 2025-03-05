require 'rails_helper'

RSpec.describe WeatherService do
    describe '#get_current_temperature' do
        it 'fetches current temperature for given coordinates' do
            VCR.use_cassette('openweathermap/current_weather') do
                service = WeatherService.new
                result = service.get_current_temperature(lat: 40.7128, lon: -74.0060)
                
                expect(result).to be_a(Hash)
                expect(result).to have_key(:temperature)
                expect(result[:temperature]).to be_a(Numeric)
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
                
                expect(result).to be_a(Hash)
                expect(result).to have_key(:daily_forecast)
                expect(result[:daily_forecast]).to be_an(Array)
                expect(result).to have_key(:from_cache)
                expect(result[:from_cache]).to be(false)
            end
        end
    end
end