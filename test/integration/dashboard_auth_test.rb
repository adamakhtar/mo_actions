require "test_helper"

class DashboardAuthTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Ada")
  end

  test "unauthenticated request to the dashboard is rejected" do
    configure_session_auth

    get mo_actions.root_path

    assert_redirected_to "/login"
  end

  test "unconfigured auth rejects with 403" do
    # reset_config! already ran in test_helper setup — defaults are closed.
    get mo_actions.root_path

    assert_response :forbidden
  end

  test "authenticated request sees the dashboard and can run an action" do
    configure_session_auth
    post "/login", params: { name: @user.name }

    get mo_actions.root_path

    assert_response :success
    assert_select "h1", "Mo Actions"
    assert_select "p.performer", "Signed in as Ada"

    post mo_actions.executions_path, params: {
      action_key: "send_invoice_reminders",
      arguments: { days_overdue: "7" }
    }
    assert_redirected_to mo_actions.executions_path(action_key: "send_invoice_reminders")
  end

  test "current_performer resolves via the configured callable" do
    MoActions.configure do |config|
      config.authenticate_with = ->(_controller) { true }
      config.current_performer = ->(_controller) { @user }
    end

    get mo_actions.root_path

    assert_response :success
    assert_select "p.performer", "Signed in as Ada"
  end

  test "symbol authenticate_with resolves on the engine controller" do
    MoActions::ApplicationController.define_method(:allow_test_dashboard) do
      head :forbidden unless current_performer
    end

    MoActions.configure do |config|
      config.authenticate_with = :allow_test_dashboard
      config.current_performer = ->(_controller) { @user }
    end

    get mo_actions.root_path

    assert_response :success
  ensure
    MoActions::ApplicationController.remove_method(:allow_test_dashboard)
  end

  private

  def configure_session_auth
    MoActions.configure do |config|
      config.authenticate_with = ->(controller) do
        controller.redirect_to "/login" unless controller.session[:user_id]
      end
      config.current_performer = ->(controller) do
        User.find_by(id: controller.session[:user_id])
      end
    end
  end
end
