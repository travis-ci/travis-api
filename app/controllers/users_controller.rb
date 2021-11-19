class UsersController < ApplicationController
  include BuildCounters, RenderEither, PermittedParams

  before_action :get_user, except: [:admins, :sync_all]

  def admins
    @admins = User.where(login: travis_config.admins).order(:name)
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

  def check_scopes
    response = Services::User::CheckScopes.new(@user).call

    if response.success?
      flash[:notice] = "Scopes checked for #{@user.login}"
    else
      flash[:error] = 'Checking scopes failed.'
    end

    redirect_to @user
  end

  def display_token
    if otp_valid?
      flash[:warning] = "This page contains the user's VCS token."
      cookies["display_token_#{@user.login}"] = {
        value: true,
        expires: 15.minutes.from_now,
      }
      Services::AuditTrail::DisplayToken.new(current_user, @user).call
    else
      flash[:error] = "One time password did not match, please try again."
    end

    redirect_to @user
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

  def gdpr
    render_either 'gdpr'
  end

  def reset_2fa
    if otp_valid?
      Travis::DataStores.redis.del("admin-v2:otp:#{@user.login}")
      Services::AuditTrail::ResetTwoFa.new(current_user, @user).call
      flash[:notice] = "Secret for #{@user.login} has been reset."
    else
      flash[:error] = 'One time password did not match, please try again.'
    end
    redirect_to admins_path
  end

  def subscription
    v2_service = Services::Billing::V2Subscription.new(params[:id], 'User')
    v2_subscription = v2_service.subscription
    if v2_subscription
      @subscription = Billing::V2SubscriptionPresenter.new(v2_subscription, params[:page], self)
      render_either 'v2_subscriptions/subscription'
    else
      subscription = Subscription.find_by(owner_id: params[:id])
      @subscription = subscription && SubscriptionPresenter.new(subscription, subscription.selected_plan, self)
      render_either 'shared/subscription'
    end
  end

  def invoices
    v2_service = Services::Billing::V2Subscription.new(params[:id], 'User')
    @invoices = v2_service.invoices

    subscription = Subscription.find_by(owner_id: params[:id])
    old_invoices = subscription && subscription.invoices.order('id DESC')

    @invoices += old_invoices if old_invoices
    render_either 'shared/invoices'
  end

  def organizations
    # there is a bug, so that @user.organizations.includes(:subscription) is not working and we get N+1 queries for subscriptions,
    # this is a workaround to get all the subscriptions at once and avoid the N+1 queries (see issue #150)
    @organizations = @user.organizations
    @subscriptions = Subscription.where(owner_id: @organizations.map(&:id)).where('owner_type = ?', 'Organization').includes(:owner)
    @subscriptions_by_organization_id = @subscriptions.group_by { |s| s.owner.id }

    v2_service = Services::Billing::V2Subscription.new(params[:id], 'User')
    v2_subscriptions = v2_service.subscriptions.select { |sub| sub.owner_type == 'Organization' }.group_by(&:owner_id)
    @subscriptions_by_organization_id.merge!(v2_subscriptions)

    render_either 'organizations'
  end

  def repositories
    @repositories_all = @user.permitted_repositories.includes(:last_build).order("active DESC NULLS LAST", :last_build_id, :owner_name, :name) #.paginate(page: params[:page], per_page: 20)
    @repositories = @repositories_all.where('permissions.admin')

    @repositories_pull = @repositories_all.where('permissions.pull')
    @repositories_push = @repositories_all.where('permissions.push')

#removing repos with admin access
    @repositories_pull = @repositories_pull.where.not('permissions.admin')
    @repositories_push = @repositories_push.where.not('permissions.admin')
    render_either 'shared/repositories'
  end

  def jobs
    repositories = @user.permitted_repositories.includes(:last_build).order("active DESC NULLS LAST", :last_build_id, :owner_name, :name)
    @pending_jobs = Job.from_repositories(repositories).not_finished
    @finished_jobs = Job.from_owner(repositories, params[:id]).finished.paginate(page: params[:page], per_page: 20)
    @last_build = @finished_jobs.first.build unless @finished_jobs.empty?
    @build_counts = build_counts(@user)
    @build_months = build_months(@user)
    render_either 'shared/jobs', locals: { owner: @user }
  end

  def requests
    repositories = @user.permitted_repositories.where("owner_id = #{params[:id]}");
    @requests = Request.from_repositories(repositories).includes(builds: :repository).order('id DESC').paginate(page: params[:page], per_page: 20)
    render_either 'shared/requests', locals: { origin: @user }
  end

  def broadcasts
    @active_broadcasts = Broadcast.active.for(@user).includes(:recipient)
    @inactive_broadcasts = Broadcast.inactive.for(@user).includes(:recipient)
    render_either 'shared/broadcasts', locals: { recipient: @user }
  end

  def show
    @display_gh_token = true if cookies["display_token_#{@user.login}"]
    @existing_boost_limit = @user.existing_boost_limit
    @normalized_boost_time = @user.normalized_boost_time
    @builds_remaining = builds_remaining_for(@user)
    @features = Features.for(@user)
    render_either 'user'
  end

  def sync
    response = Services::User::Sync.new(@user).call

    if response.success?
      flash[:notice] = "Triggered sync with VCS."
      Services::AuditTrail::Sync.new(current_user, @user).call
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @user
  end

  def reset_sync
    @user.update(is_syncing: false)
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
    flash[:notice] = "Triggered sync with VCS for all users in the organization."
    Services::AuditTrail::Sync.new(current_user, logins).call
    redirect_to back_link
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@user, current_user).call(params[:builds_allowed])
    flash[:notice] = "Added #{params[:builds_allowed]} trial builds for #{@user.login}."
    redirect_to @user
  end

  def suspend
    @user.update_attributes!(suspended: true, suspended_at: Time.now.utc)
    Services::AuditTrail::SuspendUser.new(current_user, @user).call
    flash[:notice] = "Suspended #{@user.login}."
    redirect_to @user
  end

  def unsuspend
    @user.update_attributes!(suspended: false, suspended_at: nil)
    Services::AuditTrail::UnsuspendUser.new(current_user, @user).call
    flash[:notice] = "Unsuspended #{@user.login}."
    redirect_to @user
  end

  def update_keep_netrc
    keep_netrc = keep_netrc_params[:keep_netrc] == '1'
    @user.set_keep_netrc(keep_netrc)
    flash[:notice] = "Set keep_netrc to #{keep_netrc} for #{@user.login}."
    redirect_to @user
  end

  def confirm_user
    ::Services::User::ConfirmUser.new(@user).call
    flash[:notice] = 'User confirmed.'
    redirect_to @user
  end

  def send_confirmation_email
    ::Services::User::SendConfirmationEmail.new(@user).call
    flash[:notice] = 'Confirmation email sent.'
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

  def keep_netrc_params
    permitted_keep_netrc(params.require(:user))
  end
end