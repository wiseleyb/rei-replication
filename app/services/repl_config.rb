# frozen_string_literal: true

# Basic config settings for replication
class ReplConfig
  class << self
    # Replication Slot name - can be any string
    def slot
      ENV['REPL_SLOT'] || 'repl_example'
    end

    # Time to wait before checking Replication Slot again in seconds
    def delay
      1
    end
  end
end
