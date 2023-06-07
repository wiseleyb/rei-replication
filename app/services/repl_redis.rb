# frozen_string_literal: true
# require 'connection_pool'

# Simple wrapper for Redis - to use shared connections
# List of redis commands: https://redis.io/commands/'
# Usage:
#   ReplRedis.get('some-key')
#   ReplRedis.put('some-key', 'some-value')
class ReplRedis
  class << self
    def method_missing(cmd, *args, &block)
      runcmd(cmd, *args)
    end

    def runcmd(cmd, *args)
      rconn.send(cmd, *args)
    end

    def rconn
      @redis ||= ConnectionPool::Wrapper.new do
        Redis.new(url: ENV["REDIS_URL"])
      end
    end

    # simple test of connection - used during server start up if
    # ReplConfig.use_redis? == true
    def connected?
      rconn.get("repl-redis-check-#{SecureRandom.hex}")
      true
    rescue Redis::CannotConnectError
      false
    end
  end
end

