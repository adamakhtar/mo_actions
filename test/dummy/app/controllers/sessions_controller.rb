class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_or_create_by!(name: params.require(:name))
    session[:user_id] = user.id
    redirect_to "/mo_actions"
  end

  def destroy
    reset_session
    redirect_to "/login"
  end
end
