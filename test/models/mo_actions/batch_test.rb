require_relative "../../test_helper"

module MoActions
  class BatchTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    test "legal transitions set timestamps and errors" do
      batch = new_batch
      started_at = Time.zone.local(2026, 7, 5, 12)
      finished_at = started_at + 1.minute

      travel_to started_at do
        batch.run!
        assert_equal started_at, batch.started_at
      end

      travel_to finished_at do
        batch.succeed!
        assert_equal finished_at, batch.finished_at
      end

      assert_predicate batch, :succeeded?
    end

    test "failed transition records error message" do
      batch = new_batch(status: "running", started_at: 1.minute.ago)

      batch.fail!("boom")

      assert_predicate batch, :failed?
      assert_equal "boom", batch.error_message
      assert batch.finished_at
    end

    test "illegal transitions raise invalid transition" do
      batch = new_batch

      assert_raises(InvalidTransition) { batch.succeed! }
      assert_raises(InvalidTransition) { batch.fail! }
    end

    test "position is unique within an execution" do
      duplicate = Batch.new(execution: mo_actions_executions(:running_import), position: 1)

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:position], "has already been taken"
    end

    test "positioned scope orders by position and progress is clamped" do
      first, second = mo_actions_executions(:running_import).batches.positioned
      batch = new_batch(position: 10, progress: -10)

      assert_equal [1, 2], [first.position, second.position]
      assert_equal 0, batch.progress
    end

    private

    def new_batch(attributes = {})
      Batch.create!({
        execution: mo_actions_executions(:ready_import),
        position: 1
      }.merge(attributes))
    end
  end
end
