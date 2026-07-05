module MoActions
  class LogEntry < ApplicationRecord
    LEVELS = %w[debug info warn error].freeze

    belongs_to :execution
    belongs_to :batch, optional: true

    scope :chronological, -> { order(:created_at, :id) }
    scope :for_batch, ->(batch) { where(batch: batch) }

    validates :level, presence: true, inclusion: { in: LEVELS }
    validates :message, presence: true
  end
end
