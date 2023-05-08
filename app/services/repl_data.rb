# frozen_string_literal: true

# Class wrapper for replication data pulls
#   Example data packet
#
#   {
#   "change": [
#     {
#       "kind": "update",
#       "schema": "public",
#       "table": "users",
#       "columnnames": ["id", "email", ...],
#       "columntypes": ["integer", "character varying(255)", ...],
#       "columnvalues": [120665, "", ...]
#       "oldkeys": {
#         "keynames": ["id"],
#         "keytypes": ["integer"],
#         "keyvalues": [120665]
#       }
#     }
#   ]
# }
class ReplData
  attr_accessor :row, # raw results from db
                :lsn, # ???
                :xid  # uniq id of row returned

  def initialize(row)
    @row = row
    @lsn = row['lsn']
    @xid = row['xid']
    # TODO: find faster JSON lib for this
    @data_rows = JSON.parse(row['data'])['change']
  end

  def rows
    @data_rows.map { |d| ReplDataRow.new(xid, d) }
  end
end
