# spec/jobs/cache_cleanup_job_spec.rb
require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe CacheCleanupJob, type: :job do
  describe '#perform' do
    let(:redis) { Redis.new(url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' }) }

    before do
      # Clear Redis before each test
      redis.flushdb

      # Setup test cache entries
      redis.set('current_weather_40.7128_-74.0060', { temperature: 72.5 }.to_json)
      redis.set('forecast_40.7128_-74.0060', { daily_forecast: [] }.to_json)
      redis.set('unrelated_cache_key', 'some value')
    end

    after do
      # Ensure Redis is cleared after test
      redis.flushdb
    end

    it 'removes weather-related cache entries' do
      # Perform the job
      CacheCleanupJob.new.perform

      # Verify weather-related entries are removed
      expect(redis.get('current_weather_40.7128_-74.0060')).to be_nil
      expect(redis.get('forecast_40.7128_-74.0060')).to be_nil
    end

    it 'preserves unrelated cache entries' do
      CacheCleanupJob.new.perform

      # Unrelated entry should remain intact
      expect(redis.get('unrelated_cache_key')).to eq('some value')
    end

    it 'logs the cleanup operation' do
      expect(Rails.logger).to receive(:info).with(/Periodic cache cleanup completed/)

      CacheCleanupJob.new.perform
    end

    it 'handles empty or non-existent keys gracefully' do
      # Remove all existing keys
      redis.flushdb

      # Should not raise an error
      expect { CacheCleanupJob.new.perform }.not_to raise_error
    end

    context 'with multiple weather-related entries' do
      before do
        redis.set('current_weather_37.7749_-122.4194', { temperature: 65.0 }.to_json)
        redis.set('forecast_37.7749_-122.4194', { daily_forecast: [ 1, 2, 3 ] }.to_json)
      end

      it 'removes all weather-related entries' do
        CacheCleanupJob.new.perform

        expect(redis.get('current_weather_40.7128_-74.0060')).to be_nil
        expect(redis.get('forecast_40.7128_-74.0060')).to be_nil
        expect(redis.get('current_weather_37.7749_-122.4194')).to be_nil
        expect(redis.get('forecast_37.7749_-122.4194')).to be_nil
      end
    end
  end
end
