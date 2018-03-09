class EnterpriseUsersController < ApplicationController
  def index
    @users = filter(User.order(:login)).paginate(page: params[:page], per_page: 25)
  end

  def suspend
    @user = User.find(params[:id])
    @user.update_attributes!(suspended: true, suspended_at: Time.now.utc)
    Services::AuditTrail::SuspendUser.new(current_user, @user).call
    request.xhr? ? render('replace_user') : redirect_to(enterprise_users_url(params.slice(:page, :filter)))
  end

  def unsuspend
    @user = User.find(params[:id])
    @user.update_attributes!(suspended: false, suspended_at: nil)
    Services::AuditTrail::UnsuspendUser.new(current_user, @user).call
    request.xhr? ? render('replace_user') : redirect_to(enterprise_users_url(params.slice(:page, :filter)))
  end

  private

  def filter(users)
    case params[:filter]
    when 'active'    then users.active
    when 'inactive'  then users.inactive
    when 'suspended' then users.suspended
    else                  users
    end
  end
end
