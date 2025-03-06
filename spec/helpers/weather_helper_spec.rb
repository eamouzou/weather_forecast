# spec/helpers/enhanced_weather_helper_spec.rb
require 'rails_helper'

RSpec.describe WeatherHelper, type: :helper do
  describe '#weather_icon' do
    it 'returns sun icon for clear sky' do
      expect(helper.weather_icon('clear sky')).to eq('☀️')
    end

    it 'returns cloud icon for cloudy conditions' do
      expect(helper.weather_icon('partly cloudy')).to eq('☁️')
    end

    it 'returns rain icon for rainy conditions' do
      expect(helper.weather_icon('light rain')).to eq('🌧️')
    end
    
    it 'returns drizzle icon for drizzle conditions' do
      expect(helper.weather_icon('light drizzle')).to eq('🌦️')
    end

    it 'returns snow icon for snowy conditions' do
      expect(helper.weather_icon('snow')).to eq('❄️')
    end

    it 'returns storm icon for stormy conditions' do
      expect(helper.weather_icon('thunderstorm')).to eq('⛈️')
    end
    
    it 'returns fog icon for foggy conditions' do
      expect(helper.weather_icon('fog')).to eq('🌫️')
    end
    
    it 'returns mist icon for misty conditions' do
      expect(helper.weather_icon('mist')).to eq('🌫️')
    end

    it 'returns default icon for unknown conditions' do
      expect(helper.weather_icon('unknown')).to eq('🌤️')
    end
  end

  describe '#temperature_color' do
    it 'returns blue for very cold temperatures' do
      expect(helper.temperature_color(20)).to eq('text-blue-600')
    end

    it 'returns green for mild temperatures' do
      expect(helper.temperature_color(70)).to eq('text-green-400')
    end

    it 'returns red for very hot temperatures' do
      expect(helper.temperature_color(100)).to eq('text-red-600')
    end

    it 'returns gray for nil temperatures' do
      expect(helper.temperature_color(nil)).to eq('text-gray-500')
    end
  end
  
  describe '#wind_direction_text' do
    it 'returns correct cardinal direction for north' do
      expect(helper.wind_direction_text(0)).to eq('North')
    end
    
    it 'returns correct cardinal direction for east' do
      expect(helper.wind_direction_text(90)).to eq('East')
    end
    
    it 'returns correct cardinal direction for south' do
      expect(helper.wind_direction_text(180)).to eq('South')
    end
    
    it 'returns correct cardinal direction for west' do
      expect(helper.wind_direction_text(270)).to eq('West')
    end
    
    it 'returns unknown for nil degrees' do
      expect(helper.wind_direction_text(nil)).to eq('Unknown')
    end
  end
  
  describe '#wind_speed_text' do
    it 'returns "Calm" for speeds under 1 mph' do
      expect(helper.wind_speed_text(0.5)).to eq('Calm')
    end
    
    it 'returns "Light breeze" for speeds between 4-7 mph' do
      expect(helper.wind_speed_text(5)).to eq('Light breeze')
    end
    
    it 'returns "Strong breeze" for speeds between 25-31 mph' do
      expect(helper.wind_speed_text(28)).to eq('Strong breeze')
    end
    
    it 'returns "Hurricane force" for speeds above 73 mph' do
      expect(helper.wind_speed_text(75)).to eq('Hurricane force')
    end
    
    it 'returns "Calm" for nil speed' do
      expect(helper.wind_speed_text(nil)).to eq('Calm')
    end
  end
  
  describe '#precipitation_badge' do
    it 'returns empty string for 0% chance' do
      expect(helper.precipitation_badge(0)).to eq('')
    end
    
    it 'returns formatted badge for low chance' do
      result = helper.precipitation_badge(15)
      expect(result).to include('15% chance')
      expect(result).to include('bg-blue-100')
    end
    
    it 'returns formatted badge for high chance' do
      result = helper.precipitation_badge(85)
      expect(result).to include('85% chance')
      expect(result).to include('bg-blue-500')
    end
    
    it 'returns empty string for nil chance' do
      expect(helper.precipitation_badge(nil)).to eq('')
    end
  end
  
  describe '#format_time' do
    it 'formats time correctly' do
      time = Time.new(2025, 3, 6, 14, 30, 0)
      expect(helper.format_time(time)).to eq('02:30 PM')
    end
    
    it 'returns placeholder for nil time' do
      expect(helper.format_time(nil)).to eq('--:--')
    end
  end
  
  describe '#pressure_text' do
    it 'returns "Normal pressure" for standard pressure' do
      expect(helper.pressure_text(1013)).to include('Normal pressure')
    end
    
    it 'returns "Low pressure" for low pressure' do
      expect(helper.pressure_text(990)).to include('Low pressure')
    end
    
    it 'returns "High pressure" for high pressure' do
      expect(helper.pressure_text(1030)).to include('High pressure')
    end
    
    it 'returns "Unknown" for nil pressure' do
      expect(helper.pressure_text(nil)).to eq('Unknown')
    end
  end
end

