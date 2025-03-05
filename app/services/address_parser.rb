class AddressParser
    def initialize
        @geocoder = GeocodingService.new
    end
    
    def parse(address)
        raise StandardError, "Address cannot be blank" if address.blank?
      
        if address.strip.match?(/^\d{5}$/)
            @geocoder.geocode_zip(address.strip)
        else
            @geocoder.geocode_address(address)
        end
    end
end