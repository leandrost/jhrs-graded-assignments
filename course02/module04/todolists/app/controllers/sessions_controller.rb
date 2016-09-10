class SessionsController < ApplicationController
  skip_before_action :ensure_login, only: [:new, :create]
  def new; end

  def create
    if user && user.authenticate(user_params[:password])
      create_session_and_redirect_user
    else
      redirect_to login_path, alert: "Invalid username/password combination"
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "You have been logged out"
  end

  private

  def user_params
    params.required(:user).permit(:username, :password)
  end

  def user
    @user ||= User.find_by_username(user_params[:username])
  end

  def create_session_and_redirect_user
    session[:user_id] = user.id
    redirect_to root_path, notice: "Logged in successfully"
  end
end
