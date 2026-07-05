# Configure Mo Actions from the host app.
#
# The dashboard is a Rails engine. Mount it wherever your operators should
# access it, for example:
#
#   mount MoActions::Engine => "/mo_actions"
#
MoActions.configure do |config|
  # The model class used to record who performs an action. Later phases persist
  # this value with executions, so keep it stable once runs exist.
  config.performer_class_name = "User"

  # Authentication runs before every dashboard request. Return normally to allow
  # access, or redirect/render/head to reject the request.
  #
  # Example:
  #   config.authenticate_with = ->(controller) do
  #     controller.redirect_to "/login" unless controller.session[:user_id]
  #   end
  config.authenticate_with = nil

  # Resolve the current performer record for dashboard views and future
  # executions. This callable receives the engine controller.
  #
  # Example:
  #   config.current_performer = ->(controller) do
  #     User.find_by(id: controller.session[:user_id])
  #   end
  config.current_performer = nil
end
