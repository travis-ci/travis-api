class UsersController < ApplicationController
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
      Services::JobBoost::Update.new(@user.login, current_user).call(hours, limit)
      flash[:notice] = "Owner limit set to #{limit}, and expires after #{hours} hours."
    else
      flash[:error] = "Owner limit must be greater than 0."
    end

    redirect_to @user
  end

  def display_token
    if otp_valid?
      flash[:warning] = "This page contains the user's GitHub token."
      cookies["display_token_#{@user.login}"] = {
        value: true,
        expires: 15.minutes.from_now,
      }
      Services::AuditTrail::DisplayToken.new(current_user, @user).call
      redirect_to @user
    else
      flash[:error] = "One time password did not match, please try again."
      redirect_to @user
    end
  end

  def hide_token
    cookies.delete("display_token_#{@user.login}")
    redirect_to @user
  end

  def features
    Services::Features::Update.new(@user, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@user.login}."
    redirect_to @user
  end

  def jobs
    @repositories = @user.permitted_repositories
    @finished_jobs = Job.from_repositories(@repositories).finished.paginate(page: params[:job_page], per_page: 10)
  end

  def requests
    @requests = Request.from_owner('User', params[:id]).includes(builds: :repository).order('id DESC').paginate(page: params[:request_page], per_page: 10)
  end

  def reset_2fa
    if otp_valid?
      Travis::DataStores.redis.del("admin-v2:otp:#{@user.login}")
      Services::AuditTrail::ResetTwoFa.new(current_user, @user).call
      flash[:notice] = "Secret for #{@user.login} has been reset."
    else
      flash[:error] = "One time password did not match, please try again."
    end
    redirect_to admins_path
  end

  def show
    @display_gh_token = true if cookies["display_token_#{@user.login}"]

    # there is a bug, so that @user.organizations.includes(:subscription) is not working and we get N+1 queries for subscriptions,
    # this is a workaround to get all the subscriptions at once and avoid the N+1 queries (see issue #150)
    @organizations = @user.organizations
    @subscriptions = Subscription.where(owner_id: @organizations.map(&:id)).where('owner_type = ?', 'Organization').includes(:owner)
    @subscriptions_by_organization_id = @subscriptions.group_by { |s| s.owner.id }

    @repositories = @user.permitted_repositories.includes(:last_build).order("active DESC NULLS LAST", :last_build_id, :owner_name, :name)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.paginate(page: params[:job_page], per_page: 10)

    @last_build = @finished_jobs.first.build unless @finished_jobs.empty?

    subscription = Subscription.find_by(owner_id: params[:id])

    if subscription
      @subscription = SubscriptionPresenter.new(subscription, subscription.selected_plan, self)
      @invoices = subscription.invoices.order('id DESC')
    end

    @requests = Request.from_owner('User', params[:id]).includes(builds: :repository).order('id DESC').paginate(page: params[:request_page], per_page: 10)

    @active_broadcasts = Broadcast.active.for(@user).includes(:recipient)
    @inactive_broadcasts = Broadcast.inactive.for(@user).includes(:recipient)

    @existing_boost_limit = @user.existing_boost_limit
    @normalized_boost_time = @user.normalized_boost_time

    @builds_remaining = builds_remaining_for(@user)

    @features = Features.for(@user)

    @build_counts = build_counts(@user)
    @build_months = build_months(@user)
  end

  def sync
    response = Services::User::Sync.new(@user).call

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
    user_ids  = params[:sync_all][:user_ids]

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
    Services::TrialBuilds::Update.new(@user, current_user).call(params[:builds_remaining], params[:previous_builds])
    flash[:notice] = "Reset #{@user.login}'s trial to #{params[:builds_remaining]} builds."
    redirect_to @user
  end

  private

  def get_user
    @user = User.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no user associated with ID #{params[:id]}."} if @user.nil?
  end

  def feature_params
    params.require(:features).permit(Features.for(@user).keys)
  end
end
