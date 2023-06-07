# frozen_string_literal: true

# Basic config settings for replication
class ReplConfig
  class << self
    # Try to auto create replication slot if it doesn't exist
    def auto_create_replication_slot?
      true
    end

    # Amount of time to delay bettwen pulling work from the redis-queue
    # (if using).
    # Note: that if there 10,000 things on the redis-queue it will
    # process all of those as fast as possible, then pause for this many
    # seconds before re-checking the redis-queue
    def redis_delay
      (ENV['KOYO_REPL_REDIS_DELAY'] || 1).to_i
    end

    # Redis queue name (if using) to lpush/rpop from
    def redis_queue
      'Koyo::Replication'
    end

    # Replication Slot name - can be any string
    def slot
      ENV['KOYO_REPL_SLOT'] || "koyo_repl_example_#{Rails.env}"
    end

    # Time to wait before checking Replication Slot again in seconds
    # Note: that if there 10,000 things on the replciation-queue it will
    # process all of those as fast as possible, then pause for this many
    # seconds before re-checking the replication-queue
    def sql_delay
      (ENV['KOYO_REPL_SQL_DELAY'] || 1).to_i
    end

    # When true we only "peek" the replication slot
    # Peek (when this is false):
    #   leaves the data on the postgres-replication queue
    # Read (when this is true):
    #   removes data from the postgres-replication queue
    def test_mode
      false
    end

    def use_redis?
      true
    end

  end
end
