Rails.application.config.after_initialize do
    Rails.application.config.weather_api = {
        api_key: ENV['OPENWEATHER_API_KEY'],
        base_url: 'https://api.openweathermap.org/data/2.5'
    }
end