require_relative "../../test_helper"

module MoActions
  class ExecutionTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::TimeHelpers

    test "legal preflight transitions" do
      execution = new_execution

      execution.start_preflight!
      assert_predicate execution, :preflighting?

      execution.pass_preflight!
      assert_predicate execution, :ready?
    end

    test "failed preflight returns to draft and clears preflight results" do
      execution = new_execution(status: "preflighting", preflight_results: { "blocking" => ["bad input"] })

      execution.fail_preflight!

      assert_predicate execution, :draft?
      assert_nil execution.preflight_results
    end

    test "queue run pause resume and succeed set timestamps" do
      execution = new_execution(status: "ready")
      queued_at = Time.zone.local(2026, 7, 5, 12)
      first_started_at = queued_at + 1.minute
      resumed_at = queued_at + 2.minutes
      finished_at = queued_at + 3.minutes

      travel_to queued_at do
        execution.queue!
        assert_equal queued_at, execution.queued_at
      end

      travel_to first_started_at do
        execution.run!
        assert_equal first_started_at, execution.started_at
      end

      execution.pause!
      assert_predicate execution, :paused?

      travel_to resumed_at do
        execution.run!
        assert_equal first_started_at, execution.started_at
      end

      travel_to finished_at do
        execution.succeed!
        assert_equal finished_at, execution.finished_at
      end

      assert_predicate execution, :succeeded?
      assert_predicate execution, :finished?
      assert_equal 120, execution.duration
    end

    test "fail and cancel transition to terminal states" do
      failed = new_execution(status: "running")
      cancelled = new_execution(status: "queued")

      failed.fail!("boom")
      cancelled.cancel!("operator cancelled")

      assert_predicate failed, :failed?
      assert_equal "boom", failed.error_message
      assert_predicate cancelled, :cancelled?
      assert_equal "operator cancelled", cancelled.error_message
      assert failed.finished_at
      assert cancelled.finished_at
    end

    test "illegal transitions raise invalid transition" do
      execution = new_execution(status: "draft")

      assert_raises(InvalidTransition) { execution.queue! }
      assert_raises(InvalidTransition) { execution.run! }
      assert_raises(InvalidTransition) { execution.pause! }
    end

    test "active and finished predicates reflect status groups" do
      assert_predicate mo_actions_executions(:queued_import), :active?
      assert_predicate mo_actions_executions(:running_import), :active?
      assert_predicate mo_actions_executions(:paused_import), :active?
      assert_not mo_actions_executions(:draft_import).active?
      assert_predicate mo_actions_executions(:succeeded_import), :finished?
      assert_predicate mo_actions_executions(:failed_import), :finished?
      assert_predicate mo_actions_executions(:cancelled_import), :finished?
    end

    test "arguments are writable only while draft" do
      draft = mo_actions_executions(:draft_import)
      ready = mo_actions_executions(:ready_import)

      assert draft.update(arguments: { "user_ids" => [10] })
      assert_raises(ActiveRecord::RecordInvalid) { ready.update!(arguments: { "user_ids" => [11] }) }
      assert_includes ready.errors[:arguments], "cannot be changed unless execution is draft"
    end

    test "draft argument edit clears preflight results" do
      execution = mo_actions_executions(:draft_import)
      execution.update!(preflight_results: { "checks" => ["old"] })

      execution.update!(arguments: { "user_ids" => [99] })

      assert_nil execution.reload.preflight_results
    end

    test "arguments object round trips from stored json" do
      args = Arguments.build(ImportUsersAction, {
        "source" => "api",
        "batch_size" => "25",
        "notify" => "1",
        "user_ids" => ["1", "2"]
      })
      execution = new_execution(arguments: args.to_h)

      object = execution.reload.arguments_object

      assert_predicate object, :valid?
      assert_equal "api", object.source
      assert_equal 25, object.batch_size
      assert_equal true, object.notify
      assert_equal [1, 2], object.user_ids
    end

    test "action class is resolved through registry" do
      execution = new_execution

      assert_equal ImportUsersAction, execution.action_class
    end

    test "progress outside 0 to 100 is invalid" do
      too_high = Execution.new(action_key: "import_users", performer: users(:admin), arguments: { "user_ids" => [1] }, progress: 150)
      too_low = Execution.new(action_key: "import_users", performer: users(:admin), arguments: { "user_ids" => [1] }, progress: -1)

      assert_not too_high.valid?
      assert_not too_low.valid?
      assert_includes too_high.errors[:progress], "must be less than or equal to 100"
      assert_includes too_low.errors[:progress], "must be greater than or equal to 0"
    end

    private

    def new_execution(attributes = {})
      Execution.create!({
        action_key: "import_users",
        performer: users(:admin),
        arguments: { "user_ids" => [1] }
      }.merge(attributes))
    end
  end
end
