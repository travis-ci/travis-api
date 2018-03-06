class EnterpriseUsersController < ApplicationController
  def index
    @users = User.order(:login).paginate(page: params[:page], per_page: 25)
  end

  def suspend
    @user = User.find(params[:id])
    @user.update_attributes!(suspended: true, suspended_at: Time.now.utc)
    request.xhr? ? render('replace_user') : redirect_to(enterprise_users_url(page: params[:page]))
  end

  def unsuspend
    @user = User.find(params[:id])
    @user.update_attributes!(suspended: false, suspended_at: nil)
    request.xhr? ? render('replace_user') : redirect_to(enterprise_users_url(page: params[:page]))
  end
end
