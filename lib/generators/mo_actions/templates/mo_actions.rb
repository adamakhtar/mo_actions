# Configure Mo Actions from the host app.
#
# The dashboard is a Rails engine. Mount it wherever your operators should
# access it, for example:
#
#   mount MoActions::Engine => "/mo_actions"
#
# By default the dashboard rejects every request (403) until you wire
# authenticate_with below.
#
MoActions.configure do |config|
  # Authentication runs before every dashboard request. Return normally to allow
  # access, or redirect/render/head to reject the request.
  #
  # Example with a session check:
  #   config.authenticate_with = ->(controller) do
  #     controller.redirect_to "/login" unless controller.session[:user_id]
  #   end
  #
  # Example with Devise (or similar):
  #   config.authenticate_with = ->(controller) do
  #     controller.authenticate_user!
  #   end
  config.authenticate_with = nil

  # Resolve the current performer for dashboard views and execution records.
  # Receives the engine controller. Stored polymorphically on each run.
  #
  # Example:
  #   config.current_performer = ->(controller) do
  #     User.find_by(id: controller.session[:user_id])
  #   end
  #
  # Example with Devise:
  #   config.current_performer = ->(controller) { controller.current_user }
  config.current_performer = nil
end
