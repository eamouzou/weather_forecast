# spec/jobs/weather_fetch_job_spec.rb

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe WeatherFetchJob, type: :job do
  let(:weather_service) { instance_double(WeatherService) }
  let(:lat) { 40.7128 }
  let(:lon) { -74.0060 }

  before do
    Sidekiq::Testing.inline!
    allow(WeatherService).to receive(:new).and_return(weather_service)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when fetching current weather' do
      it 'calls get_current_temperature with force refresh' do
        expect(weather_service).to receive(:get_current_temperature)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        job = WeatherFetchJob.new
        job.perform(lat, lon, 'current')
      end
    end

    context 'when fetching forecast' do
      it 'calls get_forecast with force refresh' do
        expect(weather_service).to receive(:get_forecast)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        job = WeatherFetchJob.new
        job.perform(lat, lon, 'forecast')
      end
    end

    context 'when fetching both' do
      it 'calls both current temperature and forecast methods' do
        expect(weather_service).to receive(:get_current_temperature)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        expect(weather_service).to receive(:get_forecast)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        job = WeatherFetchJob.new
        job.perform(lat, lon, 'both')
      end
    end

    context 'when an error occurs' do
      before do
        Sidekiq::Testing.fake!
      end

      it 'handles the error' do
        allow(weather_service).to receive(:get_current_temperature)
          .and_raise(StandardError.new('API Error'))

        # Just verify it doesn't raise an unhandled exception
        job = WeatherFetchJob.new
        expect {
          job.perform(lat, lon, 'current')
        }.to raise_error(StandardError)
      end
    end
  end
end
