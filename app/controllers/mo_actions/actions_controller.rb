module MoActions
  class ActionsController < ApplicationController
    def index
      @actions_by_category = Registry.by_category
    end
  end
end
