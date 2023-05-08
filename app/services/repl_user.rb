# frozen_string_literal: true

# Handles replication events for the Users table
class ReplUser
  # Handles whatever you want to do when a users row changes
  #
  # @params repl_data_row [ReplDataRow]
  def self.handle(repl_data_row)
    # just debug print here - but this is where you'd do something real
    # like call some api to update elasticsearch or something
    msg = "process-#{repl_data_row.kind} #{repl_data_row.table}"
    ReplLog.log_repl(msg)

    # optionally you could check the update type and be super specific here
    #
    # case row.kind
    # when 'insert'
    # when 'update'
    # when 'delete'
    # end
  end
end
