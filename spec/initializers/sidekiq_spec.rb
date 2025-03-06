# spec/initializers/sidekiq_spec.rb

require 'rails_helper'
require 'sidekiq'

RSpec.describe "Sidekiq Configuration" do
  before do
    # Stub environment variables
    allow(ENV).to receive(:fetch).with('REDIS_URL', anything).and_return('redis://test-redis:6379/1')
    allow(ENV).to receive(:fetch).with('SIDEKIQ_REDIS_POOL_SIZE', anything).and_return('10')
  end

  it "configures server redis correctly" do
    Sidekiq.configure_server do |config|
      expect(config.redis[:url]).to eq('redis://test-redis:6379/1')
      expect(config.redis[:size]).to eq(10)
    end
  end

  it "configures client redis correctly" do
    Sidekiq.configure_client do |config|
      expect(config.redis[:url]).to eq('redis://test-redis:6379/1')
      expect(config.redis[:size]).to eq(10)
    end
  end
end
