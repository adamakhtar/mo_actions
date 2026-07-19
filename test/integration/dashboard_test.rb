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

  test "actions index lists registered actions with run and executions links" do
    get mo_actions.root_path

    assert_response :success
    assert_select "h2", "Billing"
    assert_select "h2", "Maintenance"
    assert_select "li", /Send Invoice Reminders/
    assert_select "li", /Emails a reminder to every customer with an overdue invoice\./
    assert_select "li", /Purge Stale Sessions/
    assert_select "a[href=?]", mo_actions.new_execution_path(action_key: "purge_stale_sessions"), text: "Run"
    assert_select "a[href=?]", mo_actions.executions_path(action_key: "purge_stale_sessions"), text: "Executions"
    assert_select "a[href=?]", mo_actions.executions_path, text: "All executions"
  end

  test "run page renders argument form for typed actions" do
    get mo_actions.new_execution_path(action_key: "send_invoice_reminders")

    assert_response :success
    assert_select "h1", "Run Send Invoice Reminders"
    assert_select "form[action=?][method=post]", mo_actions.executions_path do
      assert_select "input[name=action_key][value=send_invoice_reminders]", visible: false
      assert_select "input[name='arguments[days_overdue]'][type=number]"
      assert_select "input[name='arguments[dry_run]'][type=checkbox]"
      assert_select "input[type=submit][value=Run]"
    end
  end

  test "run page for argument-free actions still confirms before create" do
    get mo_actions.new_execution_path(action_key: "purge_stale_sessions")

    assert_response :success
    assert_select "form[action=?][method=post]", mo_actions.executions_path do
      assert_select "input[name=action_key][value=purge_stale_sessions]", visible: false
      assert_select "input[name^=arguments]", count: 0
      assert_select "input[type=submit][value=Run]"
    end
  end

  test "creating an execution with arguments passes coerced values into perform" do
    post mo_actions.executions_path, params: {
      action_key: "capturing_args_test",
      arguments: { label: "hello", count: "3", enabled: "1" }
    }

    assert_redirected_to mo_actions.executions_path(action_key: "capturing_args_test")
    assert_equal(
      { label: "hello", count: 3, enabled: true },
      CapturingArgsTestAction.last_values
    )
  end

  test "creating an argument-free execution invokes perform" do
    assert_difference -> { CountingTestAction.performed_count } do
      post mo_actions.executions_path, params: { action_key: "counting_test" }
    end

    assert_redirected_to mo_actions.executions_path(action_key: "counting_test")
    follow_redirect!
    assert_select "p.notice", "Counting Test ran successfully."
  end

  test "unknown action key on new or create returns 404" do
    get mo_actions.new_execution_path(action_key: "nonexistent")
    assert_response :not_found

    assert_no_difference -> { MoActions::Execution.count } do
      post mo_actions.executions_path, params: { action_key: "nonexistent" }
    end
    assert_response :not_found
  end

  test "creating an execution records performer and arguments" do
    assert_difference -> { MoActions::Execution.count }, 1 do
      post mo_actions.executions_path, params: {
        action_key: "capturing_args_test",
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
      post mo_actions.executions_path, params: { action_key: "failing_test" }
    end

    assert_redirected_to mo_actions.executions_path(action_key: "failing_test")
    follow_redirect!
    assert_select "p.alert", "Failing Test failed: boom"

    execution = MoActions::Execution.recent.first
    assert_equal "failing_test", execution.action_key
    assert_equal "failed", execution.status
    assert_equal "boom", execution.error_message
    assert_equal @user, execution.performer
  end

  test "executions index lists recent runs for all actions" do
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

    get mo_actions.executions_path

    assert_response :success
    assert_select "h1", "Executions"
    assert_select "td", "Counting Test"
    assert_select "td", "succeeded"
    assert_select "td", "Failing Test"
    assert_select "td", "failed"
    assert_select "td", "Operator"
  end

  test "executions index filters by action_key" do
    MoActions::Execution.create!(action_key: "counting_test", status: "succeeded", arguments: {})
    MoActions::Execution.create!(action_key: "failing_test", status: "failed", arguments: {})

    get mo_actions.executions_path, params: { action_key: "counting_test" }

    assert_response :success
    assert_select "td", "Counting Test"
    assert_select "td", text: "Failing Test", count: 0
    assert_select "a[href=?]", mo_actions.new_execution_path(action_key: "counting_test"), text: /Run Counting Test/
  end

  test "executions index links each row to its detail page" do
    execution = MoActions::Execution.create!(
      action_key: "counting_test",
      status: "succeeded",
      performer: @user,
      arguments: {}
    )

    get mo_actions.executions_path

    assert_response :success
    assert_select "a[href=?]", mo_actions.execution_path(execution), text: "Counting Test"
  end

  test "execution show renders succeeded run detail" do
    execution = MoActions::Execution.create!(
      action_key: "capturing_args_test",
      status: "succeeded",
      performer: @user,
      arguments: { "label" => "hello", "count" => 3, "enabled" => true }
    )

    get mo_actions.execution_path(execution)

    assert_response :success
    assert_select "h1", "Execution"
    assert_select ".execution-detail" do
      assert_select "dd", /Capturing Args Test/
      assert_select "dd .action-key", "(capturing_args_test)"
      assert_select "dd", "succeeded"
      assert_select "dd", "Operator"
      assert_select "dd", /hello/
    end
    assert_select ".error-message", count: 0
    assert_select "a[href=?]", mo_actions.executions_path, text: "← Executions"
  end

  test "execution show renders failed run error message" do
    execution = MoActions::Execution.create!(
      action_key: "failing_test",
      status: "failed",
      performer: @user,
      arguments: {},
      error_message: "boom"
    )

    get mo_actions.execution_path(execution)

    assert_response :success
    assert_select "dd", "failed"
    assert_select "dd.error-message", "boom"
  end

  test "execution show falls back to raw key when action is unregistered" do
    execution = MoActions::Execution.create!(
      action_key: "deleted_action",
      status: "succeeded",
      arguments: { "x" => 1 }
    )

    get mo_actions.execution_path(execution)

    assert_response :success
    assert_select "dd", /deleted_action/
    assert_select "dd .action-key", "(deleted_action)"
  end

  test "unknown execution id returns 404" do
    get mo_actions.execution_path(id: 0)

    assert_response :not_found
  end

  test "blank required argument re-renders run page errors and skips persistence" do
    assert_no_difference -> { MoActions::Execution.count } do
      post mo_actions.executions_path, params: {
        action_key: "send_invoice_reminders",
        arguments: { days_overdue: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Run Send Invoice Reminders"
    assert_select "p.alert", "Please fix the errors below."
    assert_select "span.error", /Days overdue can't be blank/
  end

  test "non-numeric integer argument re-renders run page errors and skips persistence" do
    CapturingArgsTestAction.last_values = nil

    assert_no_difference -> { MoActions::Execution.count } do
      post mo_actions.executions_path, params: {
        action_key: "capturing_args_test",
        arguments: { label: "hello", count: "abc", enabled: "1" }
      }
    end

    assert_response :unprocessable_entity
    assert_nil CapturingArgsTestAction.last_values
    assert_select "input[name='arguments[label]'][value=hello]"
    assert_select "input[name='arguments[count]'][value=abc]"
    assert_select "span.error", /Count is not a number/
  end
end
