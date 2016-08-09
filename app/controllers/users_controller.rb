class UsersController < ApplicationController
  include TopazHelper

  def show
    @user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no user associated with that ID." if @user.nil?

    @repositories = @user.permitted_repositories.includes(:last_build).order(:owner_name, :name)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@user)
    @inactive_broadcasts = Broadcast.inactive.for(@user)

    @builds_remaining = Travis::DataStores.redis.get("trial:#{@user.login}")
    @builds_provided = builds_provided_for(@user)
  end

  def admins
    @admins = User.where(login: Travis::Config.load.admins).order(:name)
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
      SyncWorker.perform_async(user.id)
    end
    flash[:notice] = "Triggered sync with GitHub for #{logins.join(', ')}."
    redirect_to back_link
  end

  def update_builds_remaining
    @user = User.find_by(id: params[:id])
    Travis.redis.set("trial:#{@user.login}", params[:builds_remaining])
    flash[:notice] = "Reset #{@user.login}'s trial to #{params[:builds_remaining]} builds."
    update_topaz(@user, params[:builds_remaining], params[:previous_builds])
    redirect_to @user, anchor: 'account'
  end
end
