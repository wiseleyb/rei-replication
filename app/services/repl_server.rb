# frozen_string_literal: true

# Monitors a postgres replication slot
class ReplServer
  attr_accessor :tables, # classes that implement handle_koyo_replication(row)
                :test_mode, # when true - only peeks at slot,
                :threads # server threads running

  def self.run!
    ReplServer.new.run!
  end

  # Very basic replication handler
  # This just reads from the slot and logs that it was read. This needs to be
  # super fast and bomb proof. If this fails on a busy site your replication
  # slot will become too big to read from in short order. See README for
  # more discussion on this.
  def run!
    @threads = []

    # Run server
    threads << Thread.new do
      ReplSqlServer.run!
    end

    # Optionally (strongly recommended) use a redis queue to make
    # pulling from the replication slot as fast as possible.
    if ReplConfig.use_redis?
      # Run redis server monitor
      threads << Thread.new do
        ReplRedisServer.run!
      end
    end

    # Traps ctrl-c/z type actions allowing you to kill this if
    # testing from console. Kills threads launched above as well.
    trap("INT") do
      puts "trapping"
      threads.each{|t|
        puts "killing #{t}"
        Thread.kill t
      }
      msg = 'Killed by SystemExit, Interrupt'
      ReplLog.log_repl(msg)
    end
  end
end
