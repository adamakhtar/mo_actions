require_relative "../../test_helper"

module MoActions
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @performer = User.create!(name: "Ada")
    end

    test "mounted dashboard renders for an authenticated performer" do
      configure_dashboard_auth(current_performer: @performer)

      get "/mo_actions"

      assert_response :success
      assert_select "h1", "Mo Actions"
      assert_select "p", "Signed in as Ada"
    end

    test "unauthenticated requests are rejected" do
      configure_dashboard_auth(current_performer: nil)

      get "/mo_actions"

      assert_response :forbidden
    end

    test "symbol authentication hooks resolve against the engine controller" do
      MoActions::ApplicationController.define_method(:allow_test_dashboard) { head :forbidden unless current_performer }
      MoActions.configure do |config|
        config.authenticate_with = :allow_test_dashboard
        config.current_performer = ->(_controller) { @performer }
      end

      get "/mo_actions"

      assert_response :success
    ensure
      MoActions::ApplicationController.remove_method(:allow_test_dashboard)
    end

    private

    def configure_dashboard_auth(current_performer:)
      MoActions.configure do |config|
        config.current_performer = ->(_controller) { current_performer }
        config.authenticate_with = ->(controller) { controller.head :forbidden unless controller.current_performer }
      end
    end
  end
end
