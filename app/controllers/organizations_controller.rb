class OrganizationsController < ApplicationController
  include BuildCounters, RenderEither

  before_action :get_organization

  def boost
    limit = params[:boost][:owner_limit].to_i
    hours = params[:boost][:expires_after]
    hours = 24 if hours.blank?

    if limit > 0
      Services::JobBoost::Update.new(@organization.login, current_user).call(hours, limit)
      flash[:notice] = "Owner limit set to #{limit}, and expires after #{hours} hours."
    else
      flash[:error] = "Owner limit must be greater than 0."
    end

    redirect_to @organization
  end

  def features
    Services::Features::Update.new(@organization, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@organization.login}."
    redirect_to @organization
  end

  def subscription
    subscription = Subscription.find_by(owner_id: params[:id])
    @subscription = SubscriptionPresenter.new(subscription, subscription.selected_plan, self)
    render_either 'shared/subscription'
  end

  def invoices
    subscription = Subscription.find_by(owner_id: params[:id])
    @invoices = subscription.invoices.order('id DESC')
    render_either 'shared/invoices'
  end

  def members
    @members = @organization.users.select('users.*, memberships.role as role')
                   .order(:name)
                   .paginate(page: params[:page], per_page: 25)
    render_either 'members'
  end

  def repositories
    @repositories = @organization.repositories.where(invalidated_at: nil).order(:last_build_id, :name, :active).paginate(page: params[:page], per_page: 20)
    render_either 'shared/repositories'
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
    @requests = Request.from_owner('Organization', params[:id]).includes(builds: :repository).order('id DESC').paginate(page: params[:page], per_page: 20)
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
    render_either 'organization'
  end

  def sync
    Services::Organization::Sync.new(@organization).call
    flash[:notice] = "Triggered sync for Organization #{@organization.login}"
    redirect_back(fallback_location: root_path)
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@organization, current_user).call(params[:builds_allowed])
    flash[:notice] = "Added #{params[:builds_allowed]} trial builds for #{@organization.login}."
    redirect_to @organization
  end

  private

  def get_organization
    @organization = Organization.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no organization associated with ID #{params[:id]}."} if @organization.nil?
  end

  def feature_params
    params.require(:features).permit(Features.for(@organization).keys)
  end
end
