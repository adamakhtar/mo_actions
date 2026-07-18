class PurgeStaleSessionsAction < MoActions::Base
  display_name "Purge Stale Sessions"
  description "Deletes sessions that have been inactive for more than 30 days."
  category :maintenance

  def perform
    Rails.logger.info "Pretending to purge stale sessions."
  end
end
