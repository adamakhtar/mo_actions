require "test_helper"

class CountingTestAction < MoActions::Base
  display_name "Counting Test"
  description "Counts how many times it has been performed."
  category :testing

  class << self
    attr_accessor :performed_count
  end
  self.performed_count = 0

  def perform
    self.class.performed_count += 1
  end
end

class CapturingArgsTestAction < MoActions::Base
  display_name "Capturing Args Test"
  category :testing

  argument :label, type: :string
  argument :count, type: :integer
  argument :enabled, type: :boolean

  class << self
    attr_accessor :last_values
  end

  def perform
    self.class.last_values = { label: label, count: count, enabled: enabled }
  end
end

class FailingTestAction < MoActions::Base
  display_name "Failing Test"
  category :testing

  def perform
    raise "boom"
  end
end

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Operator")
    authenticate_as(@user)
  end

  test "dashboard lists registered actions grouped by category" do
    get mo_actions.root_path

    assert_response :success
    assert_select "h2", "Billing"
    assert_select "h2", "Maintenance"
    assert_select "li", /Send Invoice Reminders/
    assert_select "li", /Emails a reminder to every customer with an overdue invoice\./
    assert_select "li", /Purge Stale Sessions/
  end

  test "argument-free actions keep a one-click run button" do
    get mo_actions.root_path

    assert_select "form[action=?][method=post]", mo_actions.run_action_path("purge_stale_sessions") do
      assert_select "button", "Run"
      assert_select "input[name^=arguments]", count: 0
    end
  end


  test "actions with arguments render a form with typed fields" do
    get mo_actions.root_path

    assert_select "form[action=?][method=post]", mo_actions.run_action_path("send_invoice_reminders") do
      assert_select "input[name='arguments[days_overdue]'][type=number]"
      assert_select "input[name='arguments[dry_run]'][type=checkbox]"
      assert_select "input[type=submit][value=Run]"
    end
  end

  test "running an action with arguments passes coerced values into perform" do
    post mo_actions.run_action_path("capturing_args_test"), params: {
      arguments: { label: "hello", count: "3", enabled: "1" }
    }

    assert_redirected_to mo_actions.root_path
    assert_equal(
      { label: "hello", count: 3, enabled: true },
      CapturingArgsTestAction.last_values
    )
  end

  test "running an argument-free action invokes its perform method" do
    assert_difference -> { CountingTestAction.performed_count } do
      post mo_actions.run_action_path("counting_test")
    end

    assert_redirected_to mo_actions.root_path
    follow_redirect!
    assert_select "p.notice", "Counting Test ran successfully."
  end

  test "running an unknown action returns 404" do
    assert_no_difference -> { MoActions::Execution.count } do
      post mo_actions.run_action_path("nonexistent")
    end

    assert_response :not_found
  end

  test "running an action creates a succeeded execution with performer and arguments" do
    assert_difference -> { MoActions::Execution.count }, 1 do
      post mo_actions.run_action_path("capturing_args_test"), params: {
        arguments: { label: "hello", count: "3", enabled: "1" }
      }
    end

    execution = MoActions::Execution.recent.first
    assert_equal "capturing_args_test", execution.action_key
    assert_equal "succeeded", execution.status
    assert_equal @user, execution.performer
    assert_equal({ "label" => "hello", "count" => 3, "enabled" => true }, execution.arguments)
    assert_nil execution.error_message
  end

  test "perform raising records a failed execution and flashes an alert" do
    assert_difference -> { MoActions::Execution.count }, 1 do
      post mo_actions.run_action_path("failing_test")
    end

    assert_redirected_to mo_actions.root_path
    follow_redirect!
    assert_select "p.alert", "Failing Test failed: boom"

    execution = MoActions::Execution.recent.first
    assert_equal "failing_test", execution.action_key
    assert_equal "failed", execution.status
    assert_equal "boom", execution.error_message
    assert_equal @user, execution.performer
  end

  test "dashboard lists recent executions" do
    MoActions::Execution.create!(
      action_key: "counting_test",
      status: "succeeded",
      performer: @user,
      arguments: {}
    )
    MoActions::Execution.create!(
      action_key: "failing_test",
      status: "failed",
      performer: @user,
      arguments: {},
      error_message: "boom"
    )

    get mo_actions.root_path

    assert_response :success
    assert_select "section.recent-executions" do
      assert_select "h2", "Recent executions"
      assert_select "td", "Counting Test"
      assert_select "td", "succeeded"
      assert_select "td", "Failing Test"
      assert_select "td", "failed"
      assert_select "td", "Operator"
    end
  end
end
