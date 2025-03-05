# spec/services/address_parser_spec.rb
require 'rails_helper'

RSpec.describe AddressParser do
    let(:geocoding_service) { instance_double('GeocodingService') }
  
    before do
        allow(GeocodingService).to receive(:new).and_return(geocoding_service)
    end
  
    describe '#parse' do
        context 'with valid addresses' do
            it 'delegates zip codes to geocode_zip method' do
                parser = AddressParser.new
                allow(geocoding_service).to receive(:geocode_zip).with('10001').and_return({lat: 40.7128, lon: -74.0060, zip_code: '10001'})
                
                result = parser.parse('10001')
                
                expect(geocoding_service).to have_received(:geocode_zip).with('10001')
                expect(result).to be_a(Hash)
                expect(result[:lat]).to eq(40.7128)
                expect(result[:lon]).to eq(-74.0060)
                expect(result[:zip_code]).to eq('10001')
            end
        
            it 'handles zip codes with whitespace' do
                parser = AddressParser.new
                allow(geocoding_service).to receive(:geocode_zip).with('10001').and_return({lat: 40.7128, lon: -74.0060, zip_code: '10001'})
                
                result = parser.parse('  10001  ')
                
                expect(geocoding_service).to have_received(:geocode_zip).with('10001')
            end
        
            it 'delegates text addresses to geocode_address method' do
                parser = AddressParser.new
                allow(geocoding_service).to receive(:geocode_address).with('New York, NY').and_return({lat: 40.7128, lon: -74.0060})
                
                result = parser.parse('New York, NY')
                
                expect(geocoding_service).to have_received(:geocode_address).with('New York, NY')
                expect(result).to be_a(Hash)
                expect(result[:lat]).to eq(40.7128)
                expect(result[:lon]).to eq(-74.0060)
            end
        
            it 'delegates full addresses with zip code to geocode_address method' do
                parser = AddressParser.new
                allow(geocoding_service).to receive(:geocode_address).with('123 Main St, New York, NY 10001').and_return({lat: 40.7128, lon: -74.0060})
                
                result = parser.parse('123 Main St, New York, NY 10001')
                
                expect(geocoding_service).to have_received(:geocode_address).with('123 Main St, New York, NY 10001')
            end
        end
        
        context 'with invalid addresses' do
            it 'raises an error for nil input' do
                parser = AddressParser.new
                expect { parser.parse(nil) }.to raise_error(StandardError, /Address cannot be blank/)
            end
            
            it 'raises an error for empty string input' do
                parser = AddressParser.new
                expect { parser.parse('') }.to raise_error(StandardError, /Address cannot be blank/)
            end
            
            it 'raises an error for whitespace-only input' do
                parser = AddressParser.new
                expect { parser.parse('   ') }.to raise_error(StandardError, /Address cannot be blank/)
            end
        end
    end
end
