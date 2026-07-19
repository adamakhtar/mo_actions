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
      @action_class = @execution.action_class
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def new
      @action = @action_class.new(prefill_arguments)
    end

    def create
      @action = @action_class.new(argument_params)

      unless @action.execute(performer: current_performer)
        flash.now[:alert] = "Please fix the errors below."
        render :new, status: :unprocessable_entity
        return
      end

      execution = @action.execution
      if execution.succeeded?
        redirect_to executions_path(action_key: @action_class.key),
          notice: "#{@action_class.display_name} ran successfully."
      else
        redirect_to executions_path(action_key: @action_class.key),
          alert: "#{@action_class.display_name} failed: #{execution.error_message}"
      end
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

    # Copy stored args from a past execution onto the run form ("Run again").
    # Ignores missing/mismatched sources so a bare new form still works.
    def prefill_arguments
      return {} if params[:from_execution].blank?

      source = Execution.find_by(id: params[:from_execution])
      return {} unless source&.action_key == @action_class.key

      keys = @action_class.arguments.map { |argument| argument.name.to_s }
      (source.arguments || {}).slice(*keys)
    end
  end
end
