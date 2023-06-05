# frozen_string_literal: true

# Monitors a postgres replication slot
class ReplServer
  attr_accessor :tables, # classes that implement handle_koyo_replication(row)
                :test_mode # when true - only peeks at slot

  def self.run!(test_mode: false)
    ReplServer.new(test_mode: test_mode).run!
  end

  def initialize(test_mode: false)
    @test_mode = test_mode
    ReplUtils.create_replication_slot! if ReplConfig.auto_create_replication_slot?
    @tables = tables_that_handle_koyo_replication
  end

  # Very basic replication handler
  # This just reads from the slot and logs that it was read. This needs to be
  # super fast and bomb proof. If this fails on a busy a site your replication
  # slot will become too big to read from in short order. See README for
  # more discussion on this.
  #
  # @param test_mode [Boolean] - default: false. If true uses peek, which will
  # leave data in the replication slot (for testing/debugging)
  def run!
    unless can_run?
      ReplLog.log_repl('Shutting down due to errors on start-up')
      return
    end

    catch(:done) do
      check
      sleep ReplConfig.delay
      run!
    rescue SystemExit, Interrupt => e
      msg = 'Killed by SystemExit, Interrupt'
      ReplLog.log_repl(msg, err: e)
      throw(:done)
    rescue StandardError => e
      msg = "Error in ReplSerrver: #{e.message}"
      ReplLog.log_repl(msg, err: e)
      sleep ReplConfig.delay
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

        klass = tables[row.table].constantize
        klass.handle_koyo_replication(row)
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
    unless ReplUtils.replication_slot_exists?
      errs << "Error: Replication Slot doesn't exist. "\
              'See koyo-postgres-replication gem for how to set this up.'
    end
    unless tables.present?
      errs << 'Error: No models implement self.handle_koyo_replication. '\
              'See koyo-postgres-replication gem for how to set this up.'
    end

    errs.each { |msg| ReplLog.log_repl(msg) }

    errs.empty?
  end

  # Finds all models that that implement 'self.handle_koyo_replication'
  # This is only run once - during server spin up
  def tables_that_handle_koyo_replication
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
    tables
  end
end
