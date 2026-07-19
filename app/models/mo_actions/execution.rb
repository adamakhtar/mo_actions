module MoActions
  # One dashboard run of an action. Sync runs today land as succeeded or failed;
  # richer lifecycle states arrive when async/drafts need them.
  class Execution < ApplicationRecord
    STATUSES = %w[succeeded failed].freeze

    belongs_to :performer, polymorphic: true, optional: true

    validates :action_key, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :recent, -> { order(created_at: :desc, id: :desc) }

    def succeeded?
      status == "succeeded"
    end

    def failed?
      status == "failed"
    end

    def action_display_name
      Registry.find(action_key).display_name
    rescue MoActions::ActionNotFound
      action_key
    end
  end
end
