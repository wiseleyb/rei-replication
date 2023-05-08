# frozen_string_literal: true

# Monitors a postgres replication slot
class ReplServer
  # Very basic replication handler
  # This just reads from the slot and logs that it was read. This needs to be
  # super fast and bomb proof. If this fails on a busy a site your replication
  # slot will become too big to read from in short order. See README for
  # more discussion on this.
  #
  # @param test_mode [Boolean] - default: false. If true uses peek, which will
  # leave data in the replication slot (for testing/debugging)
  def self.run(test_mode: false)
    catch(:done) do
      check(test_mode:)
      sleep ReplConfig.delay
      run(test_mode:)
    rescue SystemExit, Interrupt
      msg = 'Killed by SystemExit, Interrupt'
      ReplLog.log_repl(msg, error: true)
      throw(:done)
    rescue StandardError => e
      msg = "Error in ReplSerrver: #{e.message}"
      ReplLog.log_repl(msg, error: true)
      sleep ReplConfig.delay
      run(test_mode:)
    end
  end

  # Does a single check of the replication slot
  #
  # @param test_mode [Boolean] - default: false. If true uses peek, which will
  # leave data in the replication slot (for testing/debugging)
  def self.check(test_mode: false)
    sql_results = test_mode ? ReplUtils.peek_slot : ReplUtils.read_slot!
    sql_results.each do |sql_res|
      rows = ReplData.new(sql_res).rows # returns ReplDataRow
      rows.each do |row|
        case row.table
        when 'users'
          ReplUser.handle(row)
        end
      end
    end
  end
end
