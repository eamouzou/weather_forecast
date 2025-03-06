# spec/jobs/weather_fetch_job_spec.rb

require 'rails_helper'

RSpec.describe WeatherFetchJob, type: :job do
  let(:weather_service) { instance_double(WeatherService) }
  let(:lat) { 40.7128 }
  let(:lon) { -74.0060 }

  before do
    allow(WeatherService).to receive(:new).and_return(weather_service)
  end

  describe '#perform' do
    context 'when fetching current weather' do
      it 'calls get_current_temperature with force refresh' do
        expect(weather_service).to receive(:get_current_temperature)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        WeatherFetchJob.perform_now(lat: lat, lon: lon, type: 'current')
      end
    end

    context 'when fetching forecast' do
      it 'calls get_forecast with force refresh' do
        expect(weather_service).to receive(:get_forecast)
          .with(lat: lat, lon: lon, force_refresh: true)
          .once

        WeatherFetchJob.perform_now(lat: lat, lon: lon, type: 'forecast')
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

        WeatherFetchJob.perform_now(lat: lat, lon: lon, type: 'both')
      end
    end

    context 'when an error occurs' do
      it 'retries the job' do
        allow(weather_service).to receive(:get_current_temperature)
          .and_raise(StandardError.new('API Error'))

        expect {
          WeatherFetchJob.perform_now(lat: lat, lon: lon, type: 'current')
        }.to have_enqueued_job(WeatherFetchJob)
      end
    end
  end
end