module MoActions
  class ApplicationController < ActionController::Base
    before_action :authenticate_dashboard
    helper_method :current_performer

    def current_performer
      MoActions.config.current_performer&.call(self)
    end

    private

    def authenticate_dashboard
      authenticate_with = MoActions.config.authenticate_with

      if authenticate_with.respond_to?(:call)
        authenticate_with.call(self)
      elsif authenticate_with.present?
        send(authenticate_with)
      else
        head :forbidden
      end
    end
  end
end
