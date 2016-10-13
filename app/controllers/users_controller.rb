class UsersController < ApplicationController
  include BuildCounters
  include ApplicationHelper

  before_action :get_user, except: [:admins, :sync_all]

  def admins
    @admins = User.where(login: Travis::Config.load.admins).order(:name)
  end

  def boost
    limit = params[:boost][:owner_limit].to_i
    hours = params[:boost][:expires_after]
    hours = 24 if hours.blank?

    if limit > 0
      Services::JobBoost::Update.new(@user.login, current_user).call(hours, limit)
      flash[:notice] = "Owner limit set to #{limit}, and expires after #{hours} hours."
    else
      flash[:error] = "Owner limit must be greater than 0."
    end

    redirect_to @user
  end

  def features
    Services::Features::Update.new(@user, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@user.login}."
    redirect_to @user
  end

  def show
    return redirect_to root_path, alert: "There is no user associated with that ID." if @user.nil?

    @repositories = @user.permitted_repositories.includes(:last_build).order(:owner_name, :name)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @last_build = @finished_jobs.first.build unless @finished_jobs.empty?

    subscription = Subscription.find_by(owner_id: params[:id])
    @subscription = present(subscription) unless subscription.nil?

    @active_broadcasts = Broadcast.active.for(@user)
    @inactive_broadcasts = Broadcast.inactive.for(@user)

    @existing_boost_limit = @user.existing_boost_limit
    @normalized_boost_time = @user.normalized_boost_time

    @builds_provided = builds_provided_for(@user)
    @builds_remaining = builds_remaining_for(@user)

    @features = Features.for(@user)

    @build_counts = build_counts(@user)
    @build_months = build_months(@user)
  end

  def sync
    response = Services::User::Sync.new(@user.id).call

    if response.success?
      flash[:notice] = "Triggered sync with GitHub."
      Services::AuditTrail::Sync.new(current_user, @user).call
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
    Services::AuditTrail::Sync.new(current_user, logins).call
    redirect_to back_link
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@user, current_user).call(params[:builds_remaining],params[:previous_builds])
    flash[:notice] = "Reset #{@user.login}'s trial to #{params[:builds_remaining]} builds."
    redirect_to @user
  end

  private

  def get_user
    @user = User.find_by(id: params[:id])
  end

  def feature_params
    params.require(:features).permit(Features.for(@user).keys)
  end
end
