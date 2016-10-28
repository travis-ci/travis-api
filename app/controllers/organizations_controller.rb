class OrganizationsController < ApplicationController
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
      flash[:error] = "Owner limit must be greater than 0."
    end

    redirect_to @organization
  end

  def features
    Services::Features::Update.new(@organization, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@organization.login}."
    redirect_to @organization
  end

  def show
    return redirect_to root_path, alert: "There is no organization associated with that ID." if @organization.nil?

    @repositories = @organization.repositories.includes(:last_build).order("active DESC NULLS LAST", :last_build_id, :name)

    @users = @organization.users.includes(:subscription).order(:name)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @last_build = @finished_jobs.first.build unless @finished_jobs.empty?

    subscription = Subscription.find_by(owner_id: params[:id])
    @subscription = SubscriptionPresenter.new(subscription, subscription.plans.current, self) unless subscription.nil?
    @invoices = subscription.invoices.order('id DESC') unless subscription.nil?

    @requests = Request.from_owner('Organization', params[:id]).includes(builds: :repository).order('id DESC').take(30)

    @active_broadcasts = Broadcast.active.for(@organization)
    @inactive_broadcasts = Broadcast.inactive.for(@organization)

    @existing_boost_limit = @organization.existing_boost_limit
    @normalized_boost_time = @organization.normalized_boost_time

    @builds_provided = builds_provided_for(@organization)
    @builds_remaining = builds_remaining_for(@organization)

    @features = Features.for(@organization)

    @build_counts = build_counts(@organization)
    @build_months = build_months(@organization)
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@organization, current_user).call(params[:builds_remaining],params[:previous_builds])
    flash[:notice] = "Reset #{@organization.login}'s trial to #{params[:builds_remaining]} builds."
    redirect_to @organization
  end

  private

  def get_organization
    @organization = Organization.find_by(id: params[:id])
  end

  def feature_params
    params.require(:features).permit(Features.for(@organization).keys)
  end
end
