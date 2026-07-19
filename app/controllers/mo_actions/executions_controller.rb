module MoActions
  class ExecutionsController < ApplicationController
    def index
      @action_key = params[:action_key].presence
      @action_class = Registry.all.find { |action| action.key == @action_key } if @action_key
      @executions = Execution.recent
      @executions = @executions.where(action_key: @action_key) if @action_key
      @filter_actions = Registry.all.sort_by(&:display_name)
    end

    def new
      @action_class = find_registered_action!(params[:action_key])
      return if performed?

      @action = @action_class.new
    end

    def create
      @action_class = find_registered_action!(params[:action_key])
      return if performed?

      @action = @action_class.new(argument_params)

      unless @action.valid?
        flash.now[:alert] = "Please fix the errors below."
        render :new, status: :unprocessable_entity
        return
      end

      @action.cast_arguments!

      status = "succeeded"
      error_message = nil

      begin
        @action.perform
      rescue => error
        status = "failed"
        error_message = error.message
      end

      Execution.create!(
        action_key: @action_class.key,
        arguments: @action.argument_values,
        performer: current_performer,
        status: status,
        error_message: error_message
      )

      if status == "succeeded"
        redirect_to executions_path(action_key: @action_class.key),
          notice: "#{@action_class.display_name} ran successfully."
      else
        redirect_to executions_path(action_key: @action_class.key),
          alert: "#{@action_class.display_name} failed: #{error_message}"
      end
    end

    private

    def find_registered_action!(key)
      Registry.find(key)
    rescue MoActions::ActionNotFound
      head :not_found
      nil
    end

    def argument_params
      keys = @action_class.arguments.map(&:name)
      return {} if keys.empty?

      params.fetch(:arguments, {}).permit(*keys).to_h
    end
  end
end
