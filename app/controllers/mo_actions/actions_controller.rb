module MoActions
  class ActionsController < ApplicationController
    def index
      @actions_by_category = Registry.by_category
    end

    def run
      action_class = Registry.find(params[:key])
      action_class.new(argument_params(action_class)).perform
      redirect_to root_path, notice: "#{action_class.display_name} ran successfully."
    rescue MoActions::ActionNotFound
      head :not_found
    end

    private

    def argument_params(action_class)
      keys = action_class.arguments.map(&:name)
      return {} if keys.empty?

      params.fetch(:arguments, {}).permit(*keys).to_h
    end
  end
end
