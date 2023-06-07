# frozen_string_literal: true

# Monitors a postgres replication slot
class ReplSqlServer
  @@tables = {} # somewhat expensive to create - so cache

  attr_accessor :tables,  # classes that implement handle_koyo_replication(row)
                :test_mode # when true - only peeks at slot,

  def self.run!
    new.run!
  end

  def initialize
    @test_mode = ReplConfig.test_mode
    ReplUtils.create_replication_slot! if ReplConfig.auto_create_replication_slot?
    @tables = ReplSqlServer.tables_that_handle_koyo_replication
    raise "Can't run server" unless can_run?
  end

  def run!
    catch(:done) do
      check
      sleep ReplConfig.sql_delay
      run!
    rescue StandardError => e
      msg = "Error in ReplSqlServer: #{e.message}"
      ReplLog.log_repl(msg, err: e)
      sleep ReplConfig.sql_delay
      run!
    end
  end

  # Does a single check of the replication slot
  #
  # @param test_mode [Boolean] - default: false. If true uses peek, which will
  # leave data in the replication slot (for testing/debugging)
  def check
    sql_results = test_mode ? ReplUtils.peek_slot : ReplUtils.read_slot!
    sql_results.each do |sql_res|
      rows = ReplData.new(sql_res).rows # returns ReplDataRow
      rows.each do |row|
        next unless tables.include?(row.table)

        if ReplConfig.use_redis?
          ReplRedis.lpush(ReplConfig.redis_queue, row.data.to_json)
        else
          klass = tables[row.table].constantize
          klass.handle_koyo_replication(row)
        end
      rescue StandardError => e
        ReplLog.log_repl('Unexpected Error in ReplServer.check', err: e)
      end
    end
  end

  # checks basics to see if we can run
  # logs errors (should be visible in whatever is running the server
  # returns t/f
  def can_run?
    errs = []

    # check if replication slot is setup
    unless ReplUtils.replication_slot_exists?
      errs << "Error: Replication Slot doesn't exist. "\
              'See koyo-postgres-replication gem for how to set this up.'
    end

    # check if any tables are setup to handle replication events
    unless tables.present?
      errs << 'Error: No models implement self.handle_koyo_replication. '\
              'See koyo-postgres-replication gem for how to set this up.'
    end

    # if using redis, can we connect?
    if ReplConfig.use_redis? && !ReplRedis.connected?
      errs << "Error: Can't connect to Redis. "\
              'See koyo-postgres-replication gem for how to set this up.'
    end

    # if there were any errors - let user know we're shutting down
    errs << 'Shutting down' unless errs.empty?

    errs.each { |msg| ReplLog.log_repl(msg) }

    errs.empty?
  end

  # Finds all models that that implement 'self.handle_koyo_replication'
  # This is only run once - during server spin up
  def self.tables_that_handle_koyo_replication
    return @@tables if @@tables.present?
    ReplLog.log_repl('Init: Finding models that support koyo-replication')
    tables = {}
    ActiveRecord::Base.connection.tables.map do |model|
      klass_name = model.capitalize.singularize.camelize
      klass = klass_name.constantize
      next unless klass.methods.include?(:handle_koyo_replication)

      tables[klass.table_name] = klass_name
    rescue NameError # filters out stuff like SchemaMigration
      ReplLog.log_repl("Init: ignoring model #{klass_name}")
    rescue StandardError => e
      ReplLog.log_repl('Unexpected Error in '\
                       'ReplServer.tables_that_handle_koyo_replication',
                       err: e)
    end
    tables.each do |t|
      ReplLog.log_repl("Init: registering handler #{t}")
    end
    @@tables = tables
    @@tables
  end
end
