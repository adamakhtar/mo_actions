module MoActions
  class ExecutionsController < ApplicationController
    before_action :set_editable_execution, only: [:edit, :update]
    before_action :set_ready_execution, only: :show
    before_action :set_draft_execution, only: :destroy

    def create
      execution = Execution.create!(
        action_key: action_class.key,
        performer: current_performer,
        arguments: Arguments.build(action_class, {}).to_h
      )

      redirect_to edit_execution_path(execution)
    end

    def edit
      @execution.return_to_draft! if @execution.ready?
      prepare_form
    end

    def show
      @arguments = @execution.arguments_object
    end

    def update
      @execution.return_to_draft! if @execution.ready?
      prepare_form(argument_params)
      @execution.arguments = @arguments.to_h if @arguments.castable?

      if @execution.save && @arguments.valid?
        redirect_to edit_execution_path(@execution), notice: "Draft saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @execution.destroy!
      redirect_to actions_path, notice: "Draft abandoned."
    end

    private

    def action_class
      @action_class ||= Registry.find(params.require(:action_key))
    end

    def set_editable_execution
      @execution = Execution.where(status: %w[draft ready]).find_by!(id: params[:id], performer: current_performer)
      @action_class = @execution.action_class
    end

    def set_ready_execution
      @execution = Execution.ready.find_by!(id: params[:id], performer: current_performer)
      @action_class = @execution.action_class
    end

    def set_draft_execution
      @execution = Execution.draft.find_by!(id: params[:id], performer: current_performer)
      @action_class = @execution.action_class
    end

    def prepare_form(raw_arguments = @execution.arguments)
      @arguments = Arguments.build(@action_class, raw_arguments)
      @preflight_results ||= (@execution.preflight_results || {}).symbolize_keys
    end

    def argument_params
      arguments = params.fetch(:execution, {}).fetch(:arguments, {})
      arguments.respond_to?(:permit!) ? arguments.permit! : ActionController::Parameters.new(arguments).permit!
    end
  end
end
