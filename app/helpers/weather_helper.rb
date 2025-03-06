# app/helpers/weather_helper.rb

module WeatherHelper
    def weather_icon(description)
        return "🌤️" if description.nil?

        case description.downcase
        when /clear/
            "☀️"
        when /cloud/
            "☁️"
        when /rain/
            "🌧️"
        when /snow/
            "❄️"
        when /storm/
            "⛈️"
        else
            "🌤️"
        end
    end

    def temperature_color(temp)
        return "text-primary" if temp.nil?

        case temp
        when 0..32
          "text-blue-600"  # Very cold
        when 33..50
          "text-blue-400"  # Cold
        when 51..65
          "text-green-600" # Cool
        when 66..75
          "text-green-400" # Mild
        when 76..85
          "text-yellow-600" # Warm
        when 86..95
          "text-orange-600" # Hot
        else
          "text-red-600"   # Very hot
        end
    end
end
