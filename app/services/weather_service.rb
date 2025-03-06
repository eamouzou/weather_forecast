class WeatherService
    def initialize
        @base_url = Rails.application.config.weather_api[:base_url]
        @api_key = Rails.application.config.weather_api[:api_key]
    end

    def get_current_temperature(lat:, lon:)
        fetch_with_cache("weather", lat, lon) do
            fetch_current_temperature(lat: lat, lon: lon)
        end
    end

    def get_forecast(lat:, lon:)
        fetch_with_cache("forecast", lat, lon) do
            fetch_forecast(lat: lat, lon: lon)
        end
    end

    private

    def fetch_with_cache(type, lat, lon)
        cache_key = "#{type}_#{lat}_#{lon}"

        # Check cache first
        cached_result = Rails.cache.read(cache_key)
        if cached_result.present?
            cached_result[:from_cache] = true
            return cached_result
        end

        # Execute the provided block to fetch fresh data
        result = yield

        # Store in cache for 30 minutes
        Rails.cache.write(cache_key, result, expires_in: 30.minutes)

        result
    end

    def fetch_current_temperature(lat:, lon:)
        response = make_api_request("weather", lat: lat, lon: lon)

        {
            temperature: response["main"]["temp"],
            feels_like: response["main"]["feels_like"],
            temp_min: response["main"]["temp_min"],
            temp_max: response["main"]["temp_max"],
            humidity: response["main"]["humidity"],
            description: response["weather"][0]["description"],
            from_cache: false
        }
    end

    def fetch_forecast(lat:, lon:)
        response = make_api_request("forecast", lat: lat, lon: lon)

        {
            daily_forecast: process_forecast_data(response),
            from_cache: false
        }
    end

    def make_api_request(endpoint, lat:, lon:)
        response = HTTParty.get(
            "#{@base_url}/#{endpoint}",
            query: {
                lat: lat,
                lon: lon,
                appid: @api_key,
                units: "imperial"
            }
        )

        handle_response(response)
    end

    def handle_response(response)
        if response.success?
            response
        else
            raise "API Error: #{response.code}"
        end
    end

    def process_forecast_data(response)
        # The 5-day forecast returns data in 3-hour intervals
        forecast_list = response["list"]

        # Group by date (using the dt_txt field)
        forecast_entries_grouped_by_date = forecast_list.group_by { |entry| entry["dt_txt"].split(" ").first }

        # Process each day's data
        forecast_entries_grouped_by_date.map do |date, entries|
            {
                date: date,
                high: entries.map { |entry| entry["main"]["temp_max"] }.max,
                low: entries.map { |entry| entry["main"]["temp_min"] }.min,
                description: entries.sample["weather"][0]["description"],
                humidity: entries.map { |entry| entry["main"]["humidity"] }.sum / entries.size
            }
        end
    end
end
