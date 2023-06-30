# frozen_string_literal: true

# Handles replication slot tasks for ES/Notifications
namespace :koyo do
  namespace :repl do
    # This can only be run once - no multiple servers
    desc 'Process replication slot to index changed data'
    task server: :environment do
      Koyo::Repl::PostgresServer.run!
    end
  end
end
