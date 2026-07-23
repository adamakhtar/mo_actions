module MoActions
  # Runs a persisted execution's action in the background so the dashboard
  # can redirect to the detail page and observe progress via reload.
  class RunExecutionJob < ApplicationJob
    def perform(execution_id)
      execution = Execution.find(execution_id)
      action_class = Registry.find(execution.action_key)
      action = action_class.new(execution.arguments)
      ctx = Context.new(execution)

      action.perform(ctx)
      execution.update!(status: "succeeded")
    rescue => error
      execution&.update!(status: "failed", error_message: error.message)
    end
  end
end
