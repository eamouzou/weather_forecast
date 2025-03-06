# spec/config/sidekiq_config_spec.rb

require 'rails_helper'
require 'sidekiq/config'

RSpec.describe "Sidekiq Configuration" do
  let(:config_path) { Rails.root.join('config', 'sidekiq.yml') }

  it "has a valid configuration file" do
    expect(File.exist?(config_path)).to be true
  end

  describe "configuration contents" do
    let(:config) { YAML.load_file(config_path) }

    it "sets concurrency" do
      expect(config[:concurrency]).to eq(5)
    end

    it "defines queues" do
      expect(config[:queues]).to include('default')
      expect(config[:queues]).to include('weather_fetch')
      expect(config[:queues]).to include('critical')
    end

    it "sets max retries" do
      expect(config[:max_retries]).to eq(3)
    end

    it "defines scheduled jobs" do
      # Check both symbol and string keys
      schedule = config[:schedule]
      expect(schedule.keys).to include('cache_cleanup_job')

      cache_job = schedule['cache_cleanup_job']
      expect(cache_job['cron']).to eq('0 * * * *')
      expect(cache_job['class']).to eq('CacheCleanupJob')
    end
  end
end
