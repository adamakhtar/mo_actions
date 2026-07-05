class PurgeStaleSessionsAction < MoActions::Base
  name "Purge Stale Sessions"
  description "Remove expired session records from the host app."
  category :maintenance
end
