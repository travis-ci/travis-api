class OrganizationsController < ApplicationController
  before_action :get_organization
  include TopazHelper

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

    @builds_remaining = Travis::DataStores.redis.get("trial:#{@organization.login}")
    @builds_provided = builds_provided_for(@organization)
  end

  def update_trial_builds
    @organization = Organization.find_by(id: params[:id])
    Travis::DataStores.redis.set("trial:#{@organization.login}", params[:builds_remaining])
    flash[:notice] = "Reset #{@organization.login}'s trial to #{params[:builds_remaining]} builds."
    update_topaz(@organization, params[:builds_remaining], params[:previous_builds])
    redirect_to organization_path(@organization, anchor: "account")
  end

  private
    def get_organization
      @organization = Organization.find_by(id: params[:id])
    end
end
