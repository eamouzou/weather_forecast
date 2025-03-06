# spec/helpers/weather_helper_spec.rb
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

    it 'returns snow icon for snowy conditions' do
      expect(helper.weather_icon('snow')).to eq('❄️')
    end

    it 'returns storm icon for stormy conditions' do
      expect(helper.weather_icon('thunderstorm')).to eq('⛈️')
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

    it 'returns primary for nil temperatures' do
      expect(helper.temperature_color(nil)).to eq('text-primary')
    end
  end
end
