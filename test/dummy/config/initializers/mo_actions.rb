# Dummy host wiring: session-based auth so the mounted dashboard is not open.
MoActions.configure do |config|
  config.authenticate_with = ->(controller) do
    controller.redirect_to "/login" unless controller.session[:user_id]
  end

  config.current_performer = ->(controller) do
    User.find_by(id: controller.session[:user_id])
  end
end
