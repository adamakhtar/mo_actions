require "test_helper"

class MoActions::ContextTest < ActiveSupport::TestCase
  setup do
    @execution = MoActions::Execution.create!(
      action_key: "demo_backfill",
      status: "running",
      arguments: {},
      progress_current: 0
    )
    @ctx = MoActions::Context.new(@execution)
  end

  test "total= and progress persist on the execution" do
    @ctx.total = 10
    @ctx.progress(3)

    @execution.reload
    assert_equal 10, @execution.progress_total
    assert_equal 3, @execution.progress_current
    assert_equal 30, @execution.progress_percent
  end

  test "progress clamps to total when total is set" do
    @ctx.total = 5
    @ctx.progress(99)

    assert_equal 5, @execution.reload.progress_current
  end

  test "progress clamps negative values to zero" do
    @ctx.progress(-2)

    assert_equal 0, @execution.reload.progress_current
  end
end
