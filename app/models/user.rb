# frozen_string_literal: true

class User < ApplicationRecord
  # This is called when a row is created/updated/deleted
  # You don't want to do DB updates from this or you will likely
  # create an infinite loop
  def self.handle_koyo_replication(row)
    msg = [
      '*' * 80,
      row.to_yaml,
      '*' * 80
    ]
    ReplLog.log_repl(msg)
  end
end
