require_relative "../../test_helper"

module MoActions
  class ExecutionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @performer = users(:admin)
      configure_dashboard_auth(current_performer: @performer)
    end

    test "creating an execution starts a draft for the current performer" do
      assert_difference -> { Execution.draft.count }, 1 do
        post "/mo_actions/executions", params: { action_key: "import_users" }
      end

      draft = Execution.order(:created_at).last
      assert_equal @performer, draft.performer
      assert_equal "import_users", draft.action_key
      assert_redirected_to "/mo_actions/executions/#{draft.id}/edit"
    end

    test "editing a draft renders fields from argument definitions" do
      get "/mo_actions/executions/#{mo_actions_executions(:draft_import).id}/edit"

      assert_response :success
      assert_select "h1", "Import Users"
      assert_select "p", "Where to pull users from"
      assert_select "select[name='execution[arguments][source]']"
      assert_select "input[name='execution[arguments][batch_size]']"
      assert_select "[data-controller='array-field']"
      assert_select "button", "Add user id"
      assert_select "input[disabled][placeholder='File uploads arrive in phase 7']"
    end

    test "updating a draft persists typed scalar values" do
      execution = mo_actions_executions(:draft_import)

      patch "/mo_actions/executions/#{execution.id}", params: {
        execution: {
          arguments: {
            source: "api",
            batch_size: "25",
            notify: "1",
            started_on: "2026-07-05",
            run_at: "2026-07-05T18:30",
            discount_rate: "12.5",
            user_ids: ["10"]
          }
        }
      }

      assert_redirected_to "/mo_actions/executions/#{execution.id}/edit"
      execution.reload
      assert_equal "api", execution.arguments["source"]
      assert_equal 25, execution.arguments["batch_size"]
      assert_equal true, execution.arguments["notify"]
      assert_equal "2026-07-05", execution.arguments["started_on"]
      assert_equal "12.5", execution.arguments["discount_rate"]
      assert_equal [10], execution.arguments["user_ids"]
    end

    test "invalid but castable updates show errors and keep typed draft values" do
      execution = mo_actions_executions(:draft_import)

      patch "/mo_actions/executions/#{execution.id}", params: {
        execution: {
          arguments: {
            source: "csv",
            batch_size: "0",
            notify: "0",
            user_ids: ["7", "7"]
          }
        }
      }

      assert_response :unprocessable_entity
      assert_select ".mo-actions-errors li", /must be greater than 0/
      assert_select ".mo-actions-errors li", /must contain unique values/

      execution.reload
      assert_equal 0, execution.arguments["batch_size"]
      assert_equal [7, 7], execution.arguments["user_ids"]
    end

    test "array params persist in submitted order" do
      execution = mo_actions_executions(:draft_import)

      patch "/mo_actions/executions/#{execution.id}", params: {
        execution: {
          arguments: {
            source: "csv",
            batch_size: "100",
            notify: "0",
            user_ids: ["3", "1", "2"]
          }
        }
      }

      assert_redirected_to "/mo_actions/executions/#{execution.id}/edit"
      assert_equal [3, 1, 2], execution.reload.arguments["user_ids"]
    end

    test "empty array marker round trips as an empty array" do
      execution = mo_actions_executions(:draft_import)

      patch "/mo_actions/executions/#{execution.id}", params: {
        execution: {
          arguments: {
            source: "csv",
            batch_size: "100",
            notify: "0",
            user_ids: ""
          }
        }
      }

      assert_response :unprocessable_entity
      assert_equal [], execution.reload.arguments["user_ids"]
    end

    test "abandon destroys a draft" do
      execution = mo_actions_executions(:draft_import)

      assert_difference -> { Execution.count }, -1 do
        delete "/mo_actions/executions/#{execution.id}"
      end

      assert_redirected_to "/mo_actions/actions"
    end

    test "cannot abandon a non-draft execution" do
      assert_no_difference -> { Execution.count } do
        delete "/mo_actions/executions/#{mo_actions_executions(:ready_import).id}"
      end

      assert_response :not_found
    end

    test "performer cannot edit another performer's draft" do
      other_performer = User.create!(name: "Grace")
      configure_dashboard_auth(current_performer: other_performer)

      get "/mo_actions/executions/#{mo_actions_executions(:draft_import).id}/edit"

      assert_response :not_found
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
