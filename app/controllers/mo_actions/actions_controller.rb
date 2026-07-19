module MoActions
  class ActionsController < ApplicationController
    def index
      load_index
    end

    def run
      action_class = Registry.find(params[:key])
      action = action_class.new(argument_params(action_class))

      unless action.valid?
        @invalid_action = action
        load_index
        render :index, status: :unprocessable_entity
        return
      end

      action.cast_arguments!

      status = "succeeded"
      error_message = nil

      begin
        action.perform
      rescue => error
        status = "failed"
        error_message = error.message
      end

      record_execution!(action, status: status, error_message: error_message)

      if status == "succeeded"
        redirect_to root_path, notice: "#{action_class.display_name} ran successfully."
      else
        redirect_to root_path, alert: "#{action_class.display_name} failed: #{error_message}"
      end
    rescue MoActions::ActionNotFound
      head :not_found
    end

    private

    def load_index
      @actions_by_category = Registry.by_category
      @recent_executions = Execution.recent.limit(20)
    end

    def argument_params(action_class)
      keys = action_class.arguments.map(&:name)
      return {} if keys.empty?

      params.fetch(:arguments, {}).permit(*keys).to_h
    end

    def record_execution!(action, status:, error_message: nil)
      Execution.create!(
        action_key: action.class.key,
        arguments: action.argument_values,
        performer: current_performer,
        status: status,
        error_message: error_message
      )
    end
  end
end
