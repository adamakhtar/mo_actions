module MoActions
  class DashboardController < ApplicationController
    def index
      @actions_by_category = Registry.by_category
    end
  end
end
