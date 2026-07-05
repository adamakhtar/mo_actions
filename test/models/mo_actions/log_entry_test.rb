require_relative "../../test_helper"

module MoActions
  class LogEntryTest < ActiveSupport::TestCase
    test "level must be known" do
      entry = LogEntry.new(execution: mo_actions_executions(:running_import), level: "fatal", message: "bad")

      assert_not entry.valid?
      assert_includes entry.errors[:level], "is not included in the list"
    end

    test "chronological scope orders by created at and id" do
      entries = LogEntry.where(id: [
        mo_actions_log_entries(:debug_line).id,
        mo_actions_log_entries(:started).id
      ]).chronological

      assert_equal [mo_actions_log_entries(:started), mo_actions_log_entries(:debug_line)], entries.to_a
    end

    test "for batch scope filters logs" do
      batch = mo_actions_batches(:first_running)

      assert_equal [mo_actions_log_entries(:started), mo_actions_log_entries(:debug_line)], LogEntry.for_batch(batch).chronological.to_a
    end
  end
end
