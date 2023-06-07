# Pulls from redis-queue, processes tasks
class ReplRedisServer
  attr_accessor :tables

  def initialize
    raise "Can't run redis server" unless can_run?
    @tables = ReplSqlServer.tables_that_handle_koyo_replication
  end

  def self.run!
    ReplRedisServer.new.run!
  end

  def run!
    catch(:done) do
      check
      print '.'
      sleep ReplConfig.redis_delay
      run!
    rescue StandardError => e
      msg = "Error in ReplRedisServer: #{e.message}"
      ReplLog.log_repl(msg, err: e)
      sleep ReplConfig.redis_delay
      run!
    end
  end

  def check
    row_json = ReplRedis.rpop(ReplConfig.redis_queue)
    return unless row_json
    puts 'processing'
    row = ReplDataRow.new(ReplUtils.parse_json(row_json))
    klass = tables[row.table].constantize
    klass.handle_koyo_replication(row)
  end

  # checks basics to see if we can run
  # logs errors (should be visible in whatever is running the server
  # returns t/f
  def can_run?
    return true if ReplRedis.connected?

    errs = []
    errs << "Error: Can't connect to Redis. "\
            'See koyo-postgres-replication gem for how to set this up.'
    errs << 'Shutting down' unless errs.empty?
    errs.each { |msg| ReplLog.log_repl(msg) }
    errs.empty?
  end
end
