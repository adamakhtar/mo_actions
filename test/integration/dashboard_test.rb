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

  test "each action has a run button" do
    get mo_actions.root_path

    assert_select "form[action=?][method=post]", mo_actions.run_action_path("send_invoice_reminders")
  end

  test "running an action invokes its perform method" do
    assert_difference -> { CountingTestAction.performed_count } do
      post mo_actions.run_action_path("counting_test")
    end

    assert_redirected_to mo_actions.root_path
    follow_redirect!
    assert_select "p.notice", "Counting Test ran successfully."
  end

  test "running an unknown action returns 404" do
    post mo_actions.run_action_path("nonexistent")

    assert_response :not_found
  end
end
