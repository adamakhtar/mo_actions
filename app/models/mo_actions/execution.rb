module MoActions
  class Execution < ApplicationRecord
    STATUSES = %w[draft preflighting ready queued running paused succeeded failed cancelled].freeze
    TERMINAL_STATUSES = %w[succeeded failed cancelled].freeze

    belongs_to :performer, polymorphic: true
    has_many :batches, dependent: :destroy
    has_many :log_entries, dependent: :destroy

    enum status: STATUSES.index_with(&:itself)

    validates :action_key, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    validate :arguments_writable_only_in_draft

    before_validation :clamp_progress
    before_save :clear_preflight_results_after_draft_argument_edit

    def start_preflight! = transition_to!("preflighting", from: "draft")

    def pass_preflight! = transition_to!("ready", from: "preflighting")

    def fail_preflight! = transition_to!("draft", from: "preflighting", preflight_results: nil)

    def queue! = transition_to!("queued", from: "ready", queued_at: Time.current)

    def run!
      transition_to!("running", from: %w[queued paused], started_at: started_at || Time.current)
    end

    def pause! = transition_to!("paused", from: "running")

    def succeed! = finish_as!("succeeded")

    def fail!(message = nil) = finish_as!("failed", message)

    def cancel!(message = nil) = finish_as!("cancelled", message)

    def action_class = Registry.find(action_key)

    def arguments_object = Arguments.build(action_class, arguments || {})

    def duration
      return unless started_at

      (finished_at || Time.current) - started_at
    end

    def active? = queued? || running? || paused?

    def finished? = TERMINAL_STATUSES.include?(status)

    private

    def finish_as!(status, message = nil)
      transition_to!(status, from: STATUSES - TERMINAL_STATUSES, finished_at: Time.current, error_message: message)
    end

    def transition_to!(new_status, from:, **attributes)
      allowed = Array(from)
      raise InvalidTransition, "Cannot transition execution from #{status} to #{new_status}" unless allowed.include?(status)

      update!(attributes.merge(status: new_status))
    end

    def arguments_writable_only_in_draft
      return unless persisted?
      return unless will_save_change_to_arguments?
      return if draft?

      errors.add(:arguments, "cannot be changed unless execution is draft")
    end

    def clear_preflight_results_after_draft_argument_edit
      self.preflight_results = nil if draft? && will_save_change_to_arguments?
    end

    def clamp_progress
      return if progress.nil?

      self.progress = progress.clamp(0, 100)
    end
  end
end
