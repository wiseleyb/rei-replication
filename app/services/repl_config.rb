# frozen_string_literal: true

# Basic config settings for replication
class ReplConfig
  class << self
    # Replication Slot name - can be any string
    def slot
      ENV['REPL_SLOT'] || "repl_example_#{Rails.env}"
    end

    # Time to wait before checking Replication Slot again in seconds
    def delay
      (ENV['REPL_DELAY'] || 1).to_i
    end
  end
end
