require "test_helper"

class MoActions::ExecutionTest < ActiveSupport::TestCase
  test "requires action_key and a known status" do
    execution = MoActions::Execution.new(status: "succeeded")
    assert_not execution.valid?
    assert_includes execution.errors[:action_key], "can't be blank"

    execution.action_key = "counting_test"
    execution.status = "queued"
    assert_not execution.valid?
    assert_includes execution.errors[:status], "is not included in the list"

    execution.status = "running"
    assert execution.valid?
  end

  test "recent scopes newest first" do
    older = MoActions::Execution.create!(action_key: "a", status: "succeeded", created_at: 2.minutes.ago)
    newer = MoActions::Execution.create!(action_key: "b", status: "failed", created_at: 1.minute.ago)

    assert_equal [ newer, older ], MoActions::Execution.recent.limit(2).to_a
  end

  test "action_display_name falls back to the raw key when unregistered" do
    execution = MoActions::Execution.new(action_key: "gone_action", status: "succeeded")
    assert_equal "gone_action", execution.action_display_name
  end

  test "belongs to an optional polymorphic performer" do
    user = User.create!(name: "Ada")
    execution = MoActions::Execution.create!(
      action_key: "counting_test",
      status: "succeeded",
      performer: user,
      arguments: { "label" => "hi" }
    )

    assert_equal user, execution.reload.performer
    assert_equal "User", execution.performer_type
  end

  test "progress_percent is nil without a positive total" do
    execution = MoActions::Execution.new(progress_current: 3, progress_total: nil)
    assert_nil execution.progress_percent

    execution.progress_total = 0
    assert_nil execution.progress_percent
  end
end
