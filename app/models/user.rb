# frozen_string_literal: true

# Basic users table model
class User < ApplicationRecord
  include ReplMod

  koyo_repl_handler :handle_replication

  # This is called when a row is created/updated/deleted
  # You don't want to do DB updates from this or you will likely
  # create an infinite loop
  def self.handle_replication(row)
    msg = [
      '*' * 80,
      row.to_yaml,
      '*' * 80
    ]
    ReplLog.log_repl(msg)
  end
end
