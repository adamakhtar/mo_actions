module MoActions
  class PreflightsController < ApplicationController
    before_action :set_execution

    def create
      result = PreflightRunner.new(@execution, raw_arguments: argument_params).run
      @arguments = result.arguments
      @preflight_results = result.check&.to_h

      if result.ready?
        redirect_to execution_path(@execution), notice: "Preflight passed."
      else
        render "mo_actions/executions/edit", status: :unprocessable_entity
      end
    end

    private

    def set_execution
      @execution = Execution.draft.find_by!(id: params[:execution_id], performer: current_performer)
      @action_class = @execution.action_class
    end

    def argument_params
      arguments = params.fetch(:execution, {}).fetch(:arguments, {})
      arguments.respond_to?(:permit!) ? arguments.permit! : ActionController::Parameters.new(arguments).permit!
    end
  end
end
