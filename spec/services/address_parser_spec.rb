require 'rails_helper'

RSpec.describe AddressParser do
    describe '#parse' do
        context 'with valid addresses' do
            it 'gets coordinates from a full address' do
                VCR.use_cassette('geocoding/full_address') do
                    parser = AddressParser.new
                    result = parser.parse('123 Main St, New York, NY 10001')
                    
                    expect(result).to be_a(Hash)
                    expect(result).to have_key(:lat)
                    expect(result).to have_key(:lon)
                    expect(result[:lat]).to be_within(0.1).of(40.7128)
                    expect(result[:lon]).to be_within(0.1).of(-74.0060)
                end
            end
      
            it 'gets coordinates from a city and state' do
                VCR.use_cassette('geocoding/city_state') do
                    parser = AddressParser.new
                    result = parser.parse('San Francisco, CA')
                    
                    expect(result).to be_a(Hash)
                    expect(result).to have_key(:lat)
                    expect(result).to have_key(:lon)
                    expect(result[:lat]).to be_within(0.1).of(37.7749)
                    expect(result[:lon]).to be_within(0.1).of(-122.4194)
                end
            end
      
            it 'extracts coordinates from a zip code' do
                VCR.use_cassette('geocoding/zip_code') do
                    parser = AddressParser.new
                    result = parser.parse('10001')
                    
                    expect(result).to be_a(Hash)
                    expect(result).to have_key(:lat)
                    expect(result).to have_key(:lon)
                    expect(result[:lat]).to be_a(Numeric)
                    expect(result[:lon]).to be_a(Numeric)
                    expect(result).to have_key(:zip_code)
                    expect(result[:zip_code]).to eq('10001')
                end
            end
        end
    
        context 'with invalid addresses' do
            it 'raises an error for nonsensical input' do
                VCR.use_cassette('geocoding/nonsense') do
                    parser = AddressParser.new

                    expect { parser.parse('xyzabc123$$$') }.to raise_error(StandardError, /Invalid address/)
                end
            end
            
            it 'raises an error for empty input' do
                parser = AddressParser.new

                expect { parser.parse('') }.to raise_error(StandardError, /Address cannot be blank/)
            end
            
            it 'raises an error when geocoding fails' do
                VCR.use_cassette('geocoding/service_failure') do
                    parser = AddressParser.new
                    allow_any_instance_of(HTTParty::Response).to receive(:success?).and_return(false)
                    allow_any_instance_of(HTTParty::Response).to receive(:code).and_return(500)
                    allow_any_instance_of(HTTParty::Response).to receive(:message).and_return('Internal Server Error')
                    
                    expect { parser.parse('New York') }.to raise_error(StandardError, /Geocoding API Error/)
                end
            end
        end
    end
end
