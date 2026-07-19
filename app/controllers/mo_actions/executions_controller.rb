module MoActions
  class ExecutionsController < ApplicationController
    before_action :set_action_class, only: %i[new create]

    def index
      @action_key = params[:action_key].presence
      @action_class = Registry.all.find { |action| action.key == @action_key } if @action_key
      @executions = Execution.recent
      @executions = @executions.where(action_key: @action_key) if @action_key
      @filter_actions = Registry.all.sort_by(&:display_name)
    end

    def show
      @execution = Execution.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def new
      @action = @action_class.new
    end

    def create
      @action = @action_class.new(argument_params)

      unless @action.execute(performer: current_performer)
        flash.now[:alert] = "Please fix the errors below."
        render :new, status: :unprocessable_entity
        return
      end

      execution = @action.execution.reload
      redirect_to execution_path(execution), flash_for(execution)
    end

    private

    def set_action_class
      @action_class = Registry.find(params[:action_key])
    rescue MoActions::ActionNotFound
      head :not_found
    end

    def argument_params
      keys = @action_class.arguments.map(&:name)
      return {} if keys.empty?

      params.fetch(:arguments, {}).permit(*keys).to_h
    end

    def flash_for(execution)
      name = @action_class.display_name
      case execution.status
      when "succeeded"
        { notice: "#{name} ran successfully." }
      when "failed"
        { alert: "#{name} failed: #{execution.error_message}" }
      else
        { notice: "#{name} started." }
      end
    end
  end
end
