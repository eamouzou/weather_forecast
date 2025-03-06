# app/jobs/cache_cleanup_job.rb
class CacheCleanupJob
    include Sidekiq::Job
  
    def perform
      # Use Redis directly to find and delete keys
      redis = Redis.new(url: ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' })
      
      # Find and delete weather-related keys
      weather_keys = redis.keys('current_weather_*') + redis.keys('forecast_*')
      
      # Delete found keys
      redis.del(*weather_keys) if weather_keys.any?
  
      # Log cleanup operation
      Rails.logger.info "Periodic cache cleanup completed at #{Time.current}"
    ensure
      redis.close if redis
    end
  end