# spec/services/geocoding_service_spec.rb
require 'rails_helper'

RSpec.describe GeocodingService do
  describe '#geocode_address' do
    it 'validates address is not blank' do
      service = GeocodingService.new
      expect { service.geocode_address('') }.to raise_error(StandardError, /Address cannot be blank/)
    end

    it 'handles API errors' do
      service = GeocodingService.new
      mock_response = double("Response",
        success?: false,
        code: 500,
        body: '{"cod":"500"}'
      )
      allow(HTTParty).to receive(:get).and_return(mock_response)

      expect { service.geocode_address('New York') }.to raise_error(StandardError, /Geocoding API Error/)
    end
  end

  describe '#geocode_zip' do
    it 'returns coordinates for valid US zip code', vcr: { cassette_name: 'geocoding/zip_code' } do
      service = GeocodingService.new
      result = service.geocode_zip('10001')

      expect(result).to be_a(Hash)
      expect(result).to have_key(:lat)
      expect(result).to have_key(:lon)
      expect(result[:zip_code]).to eq('10001')
    end

    it 'handles API errors' do
      service = GeocodingService.new
      mock_response = double("Response",
        success?: false,
        code: 404,
        body: '{"cod":"404","message":"not found"}'
      )
      allow(HTTParty).to receive(:get).and_return(mock_response)

      expect { service.geocode_zip('00000') }.to raise_error(StandardError, /Geocoding API Error/)
    end
  end
end
