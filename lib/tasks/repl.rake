# frozen_string_literal: true

# Handles replication slot tasks for ES/Notifications
namespace :repl do
  # This can only be run once - no multiple servers
  desc 'Process replication slot to index changed data'
  task repl_server: :environment do
    ReplPostgresServer.run!
  end
end
