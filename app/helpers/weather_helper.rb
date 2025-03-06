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
    when /drizzle/
      "🌦️"
    when /snow/
      "❄️"
    when /storm|thunder/
      "⛈️"
    when /mist|fog/
      "🌫️"
    when /haz(e|y)/
      "🌫️"
    when /dust|sand/
      "💨"
    when /tornado/
      "🌪️"
    else
      "🌤️"
    end
  end

  def temperature_color(temp)
    return "text-gray-500" if temp.nil?

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
  
  def wind_direction_text(degrees)
    return "Unknown" if degrees.nil?
    
    directions = [
      "North", "North-Northeast", "Northeast", "East-Northeast", 
      "East", "East-Southeast", "Southeast", "South-Southeast",
      "South", "South-Southwest", "Southwest", "West-Southwest", 
      "West", "West-Northwest", "Northwest", "North-Northwest"
    ]
    
    index = ((degrees + 11.25) % 360 / 22.5).floor
    directions[index]
  end
  
  def wind_speed_text(speed)
    return "Calm" if speed.nil? || speed < 1
    
    case speed
    when 0..1
      "Calm"
    when 1..3
      "Light air"
    when 4..7
      "Light breeze"
    when 8..12
      "Gentle breeze"
    when 13..18
      "Moderate breeze"
    when 19..24
      "Fresh breeze"
    when 25..31
      "Strong breeze"
    when 32..38
      "Near gale"
    when 39..46
      "Gale"
    when 47..54
      "Strong gale"
    when 55..63
      "Storm"
    when 64..72
      "Violent storm"
    else
      "Hurricane force"
    end
  end
  
  def precipitation_badge(chance)
    return "" if chance.nil? || chance == 0
    
    color_class = case chance
      when 0..20 then "bg-blue-100 text-blue-800"
      when 21..40 then "bg-blue-200 text-blue-800"
      when 41..60 then "bg-blue-300 text-blue-800"
      when 61..80 then "bg-blue-400 text-white"
      else "bg-blue-500 text-white"
    end
    
    content_tag :span, "#{chance}% chance", class: "#{color_class} px-2 py-1 rounded-full text-xs font-bold"
  end
  
  def format_time(time)
    return "--:--" if time.nil?
    time.strftime("%I:%M %p")
  end
  
  def pressure_text(pressure)
    return "Unknown" if pressure.nil?
    
    # Pressure in hPa (same as millibars)
    standard_pressure = 1013.25
    
    if pressure < (standard_pressure - 10)
      "Low pressure (#{pressure} hPa)"
    elsif pressure > (standard_pressure + 10)
      "High pressure (#{pressure} hPa)"
    else
      "Normal pressure (#{pressure} hPa)"
    end
  end
end
