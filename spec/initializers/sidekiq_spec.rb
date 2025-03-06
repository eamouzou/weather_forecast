# spec/initializers/sidekiq_spec.rb
require 'rails_helper'
require 'sidekiq'

RSpec.describe "Sidekiq Configuration" do
  context "when no custom Redis URL is set" do
    before do
      ENV.delete('REDIS_URL')
      ENV.delete('SIDEKIQ_REDIS_POOL_SIZE')
    end

    it "uses default Redis configuration" do
      Sidekiq.configure_server do |config|
        expect(config.redis[:url]).to eq('redis://localhost:6379/1')
        expect(config.redis[:size]).to eq(5)
      end
    end
  end

  context "when custom Redis URL is set" do
    before do
      ENV['REDIS_URL'] = 'redis://custom-redis:6379/2'
      ENV['SIDEKIQ_REDIS_POOL_SIZE'] = '10'
    end

    after do
      ENV.delete('REDIS_URL')
      ENV.delete('SIDEKIQ_REDIS_POOL_SIZE')
    end

    it "uses custom Redis configuration" do
      Sidekiq.configure_server do |config|
        expect(config.redis[:url]).to eq('redis://custom-redis:6379/2')
        expect(config.redis[:size]).to eq(10)
      end
    end
  end
end
