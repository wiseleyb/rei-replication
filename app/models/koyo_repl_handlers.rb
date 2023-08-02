class KoyoReplHandlers
  # example row:
  # User.handle_replcation called
  # TODO: Add link to class returned
  def self.koyo_handle_all_replication(row)
    msg = [
      'a' * 80,
      'ReplCatchAll.koyo_handle_all_replication called',
      row.to_yaml,
      'a' * 80
    ]
    # puts msg
  end

  # log_leve: :debug, :info, :warn, :error
  # Example of message
  # source=KoyoReplication logid=d7f1f0bb2a
  #   message=Init: Finding models that support koyo_repl_handler
  def self.koyo_log_event(message, log_level)
    msg = [
      'b' * 80,
      log_level,
      message,
      'b' * 80
    ]
    # pp message
    # puts msg
  end
end
