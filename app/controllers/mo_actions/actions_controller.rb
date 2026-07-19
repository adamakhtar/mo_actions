module MoActions
  class ActionsController < ApplicationController
    def index
      @actions_by_category = Registry.by_category
      @recent_executions = Execution.recent.limit(20)
    end

    def run
      action_class = Registry.find(params[:key])
      raw_arguments = argument_params(action_class)
      instance = action_class.new(raw_arguments)
      stored_arguments = serialize_arguments(instance)

      status = "succeeded"
      error_message = nil

      begin
        instance.perform
      rescue => error
        status = "failed"
        error_message = error.message
      end

      record_execution!(
        action_class,
        stored_arguments,
        status: status,
        error_message: error_message
      )

      if status == "succeeded"
        redirect_to root_path, notice: "#{action_class.display_name} ran successfully."
      else
        redirect_to root_path, alert: "#{action_class.display_name} failed: #{error_message}"
      end
    rescue MoActions::ActionNotFound
      head :not_found
    end

    private

    def argument_params(action_class)
      keys = action_class.arguments.map(&:name)
      return {} if keys.empty?

      params.fetch(:arguments, {}).permit(*keys).to_h
    end

    def serialize_arguments(instance)
      instance.class.arguments.each_with_object({}) do |definition, hash|
        hash[definition.name.to_s] = instance.public_send(definition.name)
      end
    end

    def record_execution!(action_class, arguments, status:, error_message: nil)
      Execution.create!(
        action_key: action_class.key,
        arguments: arguments,
        performer: current_performer,
        status: status,
        error_message: error_message
      )
    end
  end
end
