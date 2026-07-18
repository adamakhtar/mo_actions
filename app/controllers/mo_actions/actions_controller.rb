module MoActions
  class ActionsController < ApplicationController
    def index
      @actions_by_category = Registry.by_category
    end

    def run
      action = Registry.find(params[:key])
      action.new.perform
      redirect_to root_path, notice: "#{action.display_name} ran successfully."
    rescue MoActions::ActionNotFound
      head :not_found
    end
  end
end
