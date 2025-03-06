# config/initializers/redis.rb
require 'redis'
require 'connection_pool'

redis_url = ENV.fetch('REDIS_URL') { 'redis://localhost:6379/1' }

# Create a connection pool for Redis
REDIS_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  Redis.new(url: redis_url)
end

# Convenience method to access Redis
def with_redis(&block)
  REDIS_POOL.with(&block)
end