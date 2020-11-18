class OrganizationsController < ApplicationController
  include PermittedParams
  include RenderEither
  include BuildCounters

  before_action :get_organization

  def boost
    limit = params[:boost][:owner_limit].to_i
    hours = params[:boost][:expires_after]
    hours = 24 if hours.blank?

    if limit > 0
      Services::JobBoost::Update.new(@organization.login, current_user).call(hours, limit)
      flash[:notice] = "Owner limit set to #{limit}, and expires after #{hours} hours."
    else
      flash[:error] = 'Owner limit must be greater than 0.'
    end

    redirect_to @organization
  end

  def features
    Services::Features::Update.new(@organization, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@organization.login}."
    redirect_to @organization
  end

  def subscription
    v2_service = Services::Billing::V2Subscription.new(params[:id], 'Organization')
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
    v2_service = Services::Billing::V2Subscription.new(params[:id], 'Organization')
    @invoices = v2_service.invoices

    subscription = Subscription.find_by(owner_id: params[:id])
    old_invoices = subscription && subscription.invoices.order('id DESC')

    @invoices += old_invoices if old_invoices
    render_either 'shared/invoices'
  end

  def members
    all_members = @organization.users.select('users.*, memberships.role as role, memberships.build_permission as build_permission')
    @members = all_members.order(:name).paginate(page: params[:page], per_page: 25)
    @members_amount = "(#{all_members.length})" if all_members.present?
    render_either 'members'
  end

  def repositories
    @repositories = @organization.repositories
                                 .where(invalidated_at: nil)
                                 .order(:last_build_id, :name, :active)
      #                           .paginate(page: params[:page], per_page: 20)
    render_either 'shared/repositories'
  end

  def update_member_permissions
    current_user_ids = @organization.memberships.pluck(:user_id)
    allowed_user_ids = params[:allowed_users] || []
    allowed_user_ids = allowed_user_ids.map(&:to_i) & current_user_ids if allowed_user_ids.present?
    forbidden_user_ids = current_user_ids - allowed_user_ids

    if allowed_user_ids.blank? && forbidden_user_ids.blank?
      redirect_to @organization
      return
    end

    ActiveRecord::Base.transaction do
      @organization.memberships.where(user_id: allowed_user_ids).update_all(build_permission: true) if allowed_user_ids.present?
      @organization.memberships.where(user_id: forbidden_user_ids).update_all(build_permission: false) if forbidden_user_ids.present?
    end

    flash[:notice] = 'Updated user permissions'
    redirect_to @organization
  end

  def jobs
    repositories = @organization.repositories.where(invalidated_at: nil).order(:last_build_id, :name, :active)
    @jobs = Job.from_repositories(repositories)
    @pending_jobs = @jobs.not_finished
    @finished_jobs = @jobs.finished.paginate(page: params[:page], per_page: 20)
    @last_build = @finished_jobs.first.build unless @finished_jobs.empty?
    @build_counts = build_counts(@organization)
    @build_months = build_months(@organization)
    render_either 'shared/jobs', locals: { owner: @organization }
  end

  def requests
    repositories = @organization.repositories.where(invalidated_at: nil).order(:last_build_id, :name, :active)
    @requests = Request.from_repositories(repositories)
                       .includes(builds: :repository)
                       .order('id DESC')
                       .paginate(page: params[:page], per_page: 20)
    render_either 'shared/requests', locals: { origin: @organization }
  end

  def broadcasts
    @active_broadcasts = Broadcast.active.for(@organization).includes(:recipient)
    @inactive_broadcasts = Broadcast.inactive.for(@organization).includes(:recipient)
    render_either 'shared/broadcasts', locals: { recipient: @organization }
  end

  def show
    @existing_boost_limit = @organization.existing_boost_limit
    @normalized_boost_time = @organization.normalized_boost_time
    @builds_remaining = builds_remaining_for(@organization)
    @features = Features.for(@organization)
    @installation = @organization.installation
    render_either 'organization'
  end

  def sync
    response = Services::Organization::Sync.new(@organization).call

    flash[:notice] = if response.success?
                       "Triggered sync for Organization #{@organization.login}"
                     else
                       "Sync for Organization #{@organization.login} failed"
                     end

    redirect_back(fallback_location: root_path)
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@organization, current_user).call(params[:builds_allowed])
    flash[:notice] = "Added #{params[:builds_allowed]} trial builds for #{@organization.login}."
    redirect_to @organization
  end

  def update_keep_netrc
    keep_netrc = keep_netrc_params[:keep_netrc] == '1'
    @organization.set_keep_netrc(keep_netrc)
    flash[:notice] = "Set keep_netrc to #{keep_netrc} for #{@organization.login}."
    redirect_to @organization
  end

  private

  def get_organization
    @organization = Organization.find_by(id: params[:id])
    return if @organization.present?

    redirect_to not_found_path, flash: { error: "There is no organization associated with ID #{params[:id]}." }
  end

  def feature_params
    params.require(:features).permit(Features.for(@organization).keys)
  end

  def keep_netrc_params
    permitted_keep_netrc(params.require(:organization))
  end
end
