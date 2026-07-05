class ImportUsersAction < MoActions::Base
  name "Import Users"
  description "Import users from an uploaded source."
  category :billing

  argument :source, :enum, values: %w[csv api], default: "csv", description: "Where to pull users from"
  argument :batch_size, :integer, default: 100, validates: { numericality: { greater_than: 0 } }
  argument :notify, :boolean, default: false
  argument :started_on, :date, required: false
  argument :run_at, :datetime, required: false
  argument :discount_rate, :decimal, required: false, validates: { numericality: { greater_than_or_equal_to: 0 } }
  argument :user_ids, :integer, array: true, required: true,
           array_validates: { min_items: 1, max_items: 500, unique: true }
  argument :mapping_file, :file, required: false

  def preflight(args, check)
    check.error "User 13 cannot be imported" if args.user_ids.include?(13)
    check.warn "Large batches may take longer to process" if args.batch_size > 250
    check.info "Will import #{args.user_ids.size} user(s) from #{args.source}"
  end
end
