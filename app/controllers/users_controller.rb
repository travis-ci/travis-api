class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no user associated with that ID." if @user.nil?

    @repositories = @user.permitted_repositories.includes(:last_build)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@user)
    @inactive_broadcasts = Broadcast.inactive.for(@user)
  end

  def sync
    @user = User.find_by(id: params[:id])

    response = Services::User::Sync.new(@user.id).call

    if response.success?
      flash[:notice] = "Triggered sync with GitHub."
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @user
  end

  def sync_all
    back_link = params[:sync_all][:back_link]
    user_ids = params[:sync_all][:user_ids]

    logins = []

    user_ids.split(',').each do |id|
      next unless user = User.find_by(id: id)
      logins << user.login
      Services::User::Sync.new(user.id).call
    end
    flash[:notice] = "Triggered sync with GitHub for #{logins.join(', ')}."
    redirect_to back_link
  end
end
