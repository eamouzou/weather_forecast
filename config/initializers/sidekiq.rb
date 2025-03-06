# config/initializers/sidekiq.rb

require "sidekiq"

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
    size: ENV.fetch("SIDEKIQ_REDIS_POOL_SIZE") { 5 }
  }

  # Optional: Configure server middleware
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
    size: ENV.fetch("SIDEKIQ_REDIS_POOL_SIZE") { 5 }
  }
end
