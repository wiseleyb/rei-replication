# frozen_string_literal: true

# Basic users table model
class User < ApplicationRecord
  include Koyo::Repl::Mod

  # register method for replication
  koyo_repl_handler :handle_replication

  # This is called when a row is created/updated/deleted
  # You don't want to do DB updates from this or you will likely
  # create an infinite loop
  def self.handle_replication(row)
    puts '&' * 80
    puts Admin.first.to_yaml
    puts '&' * 80
    msg = [
      '*' * 80,
      'User.handle_replcation called',
      row.to_yaml,
      '*' * 80
    ]
    puts msg
  end
end
