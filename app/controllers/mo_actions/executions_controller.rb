module MoActions
  class ExecutionsController < ApplicationController
    before_action :set_execution, only: [:edit, :update, :destroy]

    def create
      execution = Execution.create!(
        action_key: action_class.key,
        performer: current_performer,
        arguments: Arguments.build(action_class, {}).to_h
      )

      redirect_to edit_execution_path(execution)
    end

    def edit
      prepare_form
    end

    def update
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

    def set_execution
      @execution = Execution.draft.find_by!(id: params[:id], performer: current_performer)
      @action_class = @execution.action_class
    end

    def prepare_form(raw_arguments = @execution.arguments)
      @arguments = Arguments.build(@action_class, raw_arguments)
    end

    def argument_params
      params.fetch(:execution, {}).fetch(:arguments, {}).permit!
    end
  end
end
