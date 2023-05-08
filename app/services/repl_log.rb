# frozen_string_literal: true

# Performns basic logging around replication
class ReplLog
  class << self
    # @param [Hash] data to add to log message
    def log_repl(message, data = {})
      return if message.blank?

      h = {
        source: 'Replication',
        message:
      }.merge(data)
      log_hash(h)
    end

    def log_hash(hash)
      msg = hash.map { |k, v| "#{k}=#{v}" }.join(' ')
      Rails.logger.info msg
      puts "ReplLog: #{msg}"
    end
  end
end
