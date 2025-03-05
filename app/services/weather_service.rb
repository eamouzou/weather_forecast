class WeatherService
    def initialize
        @base_url = Rails.application.config.weather_api[:base_url]
        @api_key = Rails.application.config.weather_api[:api_key]
    end

    def get_current_temperature(lat:, lon:)
        response = make_api_request("weather", lat: lat, lon: lon)
        
        {
            temperature: response['main']['temp'],
            from_cache: false
        }
    end
    
    def get_forecast(lat:, lon:)
        response = make_api_request("forecast", lat: lat, lon: lon)
        
        {
            daily_forecast: process_forecast_data(response),
            from_cache: false
        }
    end
      
    private
      
    def make_api_request(endpoint, lat:, lon:)
        response = HTTParty.get(
            "#{@base_url}/#{endpoint}",
            query: {
                lat: lat,
                lon: lon,
                appid: @api_key,
                units: 'imperial'
            }
        )
        
        handle_response(response)
    end
    
    def handle_response(response)
        if response.success?
            response
        else
            raise "API Error: #{response.code} - #{response.message}"
        end
    end

    def process_forecast_data(response)
        # The 5-day forecast returns data in 3-hour intervals
        # Group by day and get high/low temps
        forecast_list = response['list']
        
        # Group by date (using the dt_txt field)
        forecast_entries_grouped_by_date = forecast_list.group_by { |forecast_entry| forecast_entry['dt_txt'].split(' ').first }
        
        # Process each day's data (date, max temp, min temp, sample descr, avg humidity)
        forecast_entries_grouped_by_date.map do |date, forecast_entries|
            {
                date: date,
                high: forecast_entries.map { |entry| entry['main']['temp_max'] }.max,
                low: forecast_entries.map { |entry| entry['main']['temp_min'] }.min,
                description: forecast_entries.sample['weather'][0]['description'],
                humidity: forecast_entries.map { |entry| entry['main']['humidity'] }.sum / forecast_entries.size
            }
        end
    end
  end