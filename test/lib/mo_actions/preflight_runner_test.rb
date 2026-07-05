require_relative "../../test_helper"

class ExplodingPreflightAction < MoActions::Base
  key "exploding_preflight"
  name "Exploding Preflight"
  category :maintenance

  argument :user_ids, :integer, array: true, required: true,
           array_validates: { min_items: 1 }

  def preflight(_args, _check)
    raise "boom"
  end
end

module MoActions
  class PreflightRunnerTest < ActiveSupport::TestCase
    setup do
      Registry.register(ExplodingPreflightAction)
    end

    test "schema invalid returns to draft with argument errors" do
      execution = mo_actions_executions(:draft_import)

      result = PreflightRunner.new(execution, raw_arguments: { user_ids: "" }).run

      assert_predicate execution.reload, :draft?
      assert_predicate result, :schema_invalid?
      assert_includes result.arguments.errors[:user_ids], "must have at least 1 item(s)"
      assert_nil execution.preflight_results
    end

    test "preflight errors return to draft and store blocking results" do
      execution = mo_actions_executions(:draft_import)

      result = PreflightRunner.new(execution, raw_arguments: { user_ids: ["13"] }).run

      assert_predicate execution.reload, :draft?
      assert_predicate result, :preflight_failed?
      assert_equal ["User 13 cannot be imported"], execution.preflight_results["errors"]
    end

    test "preflight pass stores informational results and readies execution" do
      execution = mo_actions_executions(:draft_import)

      result = PreflightRunner.new(execution, raw_arguments: { batch_size: "300", user_ids: ["1", "2"] }).run

      assert_predicate execution.reload, :ready?
      assert_predicate result, :ready?
      assert_equal ["Will import 2 user(s) from csv"], execution.preflight_results["infos"]
      assert_equal ["Large batches may take longer to process"], execution.preflight_results["warnings"]
    end

    test "preflight exceptions are stored as blocking errors" do
      execution = Execution.create!(
        action_key: "exploding_preflight",
        performer: users(:admin),
        arguments: { "user_ids" => [1] }
      )

      assert_nothing_raised do
        PreflightRunner.new(execution, raw_arguments: { user_ids: ["1"] }).run
      end

      assert_predicate execution.reload, :draft?
      assert_equal ["RuntimeError: boom"], execution.preflight_results["errors"]
    end

    test "action without preflight passes straight to ready" do
      execution = Execution.create!(
        action_key: "purge_stale_sessions",
        performer: users(:admin),
        arguments: {}
      )

      PreflightRunner.new(execution, raw_arguments: {}).run

      assert_predicate execution.reload, :ready?
      assert_equal [], execution.preflight_results["errors"]
      assert_equal [], execution.preflight_results["infos"]
      assert_equal [], execution.preflight_results["warnings"]
    end
  end
end
