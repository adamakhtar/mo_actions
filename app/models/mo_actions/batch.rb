module MoActions
  class Batch < ApplicationRecord
    STATUSES = %w[pending running succeeded failed skipped].freeze

    belongs_to :execution
    has_many :log_entries, dependent: :nullify

    enum :status, STATUSES.index_with(&:itself)

    scope :positioned, -> { order(:position) }

    validates :status, presence: true, inclusion: { in: STATUSES }
    validates :position, presence: true, uniqueness: { scope: :execution_id }
    validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    def run! = transition_to!("running", from: "pending", started_at: Time.current)

    def succeed! = transition_to!("succeeded", from: "running", finished_at: Time.current)

    def fail!(message = nil) = transition_to!("failed", from: "running", finished_at: Time.current, error_message: message)

    private

    def transition_to!(new_status, from:, **attributes)
      allowed = Array(from)
      raise InvalidTransition, "Cannot transition batch from #{status} to #{new_status}" unless allowed.include?(status)

      update!(attributes.merge(status: new_status))
    end

  end
end
