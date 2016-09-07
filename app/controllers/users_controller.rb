class UsersController < ApplicationController
  before_action :get_user, except: [:admins, :sync_all]
  include BuildCounters

  before_action :get_user, except: [:admins, :sync_all]

  def admins
    @admins = User.where(login: Travis::Config.load.admins).order(:name)
  end

  def boost
    limit = params[:boost][:owner_limit].to_i
    hours = params[:boost][:expires_after]
    hours = 24 if hours.blank?

    if limit > 0
      Services::JobBoost::Update.new(@user.login).call(hours, limit)
      flash[:notice] = "Owner limit set to #{limit}, and expires after #{hours} hours."
    else
      flash[:error] = "Owner limit must be greater than 0."
    end

    redirect_to user_path(@user, anchor: 'account')
  end

  def features
    Services::Features::Update.new(@user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@user.login}."
    redirect_to user_path(@user, anchor: "account")
  end

  def show
    return redirect_to root_path, alert: "There is no user associated with that ID." if @user.nil?

    @repositories = @user.permitted_repositories.includes(:last_build).order(:owner_name, :name)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@user)
    @inactive_broadcasts = Broadcast.inactive.for(@user)

    @existing_boost_limit = @user.existing_boost_limit
    @normalized_boost_time = @user.normalized_boost_time

    @builds_remaining = Travis::DataStores.redis.get("trial:#{@user.login}")
    @builds_provided = builds_provided_for(@user)

    @features = Features.for(@user)
  end

  def sync
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

  def update_trial_builds
    Services::TrialBuilds::Update.new(@user).call(params[:builds_remaining],params[:previous_builds])
    flash[:notice] = "Reset #{@user.login}'s trial to #{params[:builds_remaining]} builds."
    redirect_to user_path(@user, anchor: "account")
  end

  private

  def get_user
    @user = User.find_by(id: params[:id])
  end

  def feature_params
    params.require(:features).permit(Features.for(@user).keys)
  end
end
