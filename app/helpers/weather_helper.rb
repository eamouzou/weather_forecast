# app/helpers/weather_helper.rb

module WeatherHelper
    def weather_icon(description)
        case description.downcase
        when /clear/
            '☀️'
        when /cloud/
            '☁️'
        when /rain/
            '🌧️'
        when /snow/
            '❄️'
        when /storm/
            '⛈️'
        else
            '🌤️'
        end
    end
end
