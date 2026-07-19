module MoActions
  # One dashboard run of an action. Created as +running+ before work starts;
  # the job lands it on succeeded or failed. Progress is optional (total may
  # be nil until the action sets it).
  class Execution < ApplicationRecord
    STATUSES = %w[running succeeded failed].freeze

    belongs_to :performer, polymorphic: true, optional: true

    validates :action_key, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :progress_current, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :recent, -> { order(created_at: :desc, id: :desc) }

    def running?
      status == "running"
    end

    def succeeded?
      status == "succeeded"
    end

    def failed?
      status == "failed"
    end

    def progress_percent
      return nil if progress_total.nil? || progress_total.zero?

      ((progress_current.to_f / progress_total) * 100).round
    end

    def action_display_name
      Registry.find(action_key).display_name
    rescue MoActions::ActionNotFound
      action_key
    end
  end
end
