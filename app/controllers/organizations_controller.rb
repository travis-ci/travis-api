class OrganizationsController < ApplicationController
  before_action :get_organization
  include BuildCounters

  before_action :get_organization

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

    redirect_to user_path(@organization, anchor: 'account')
  end

  def features
    Services::Features::Update.new(@organization).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@organization.login}."
    redirect_to organization_path(@organization, anchor: "account")
  end

  def show
    return redirect_to root_path, alert: "There is no organization associated with that ID." if @organization.nil?

    @repositories = @organization.repositories.includes(:last_build).order(:name)

    @users = @organization.users.includes(:subscription)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@organization)
    @inactive_broadcasts = Broadcast.inactive.for(@organization)

    @existing_boost_limit = @organization.existing_boost_limit
    @normalized_boost_time = @organization.normalized_boost_time

    @builds_remaining = builds_remaining(@organization)
    @builds_provided = builds_provided_for(@organization)

    @features = Features.for(@organization)

    @build_counts = build_counts(@organization)
    @build_months = build_months(@user)
  end

  def update_trial_builds
    Services::TrialBuilds::Update.new(@organization).call(params[:builds_remaining],params[:previous_builds])
    flash[:notice] = "Reset #{@organization.login}'s trial to #{params[:builds_remaining]} builds."
    redirect_to organization_path(@organization, anchor: "account")
  end

  private

  def get_organization
    @organization = Organization.find_by(id: params[:id])
  end

  def feature_params
    params.require(:features).permit(Features.for(@organization).keys)
  end
end
