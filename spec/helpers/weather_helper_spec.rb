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
end
