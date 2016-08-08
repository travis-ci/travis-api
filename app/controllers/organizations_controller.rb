class OrganizationsController < ApplicationController
  include TopazHelper

  def show
    @organization = Organization.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no organization associated with that ID." if @organization.nil?

    @repositories = @organization.repositories.includes(:last_build).order(:name)

    @users = @organization.users.includes(:subscription)

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@organization)
    @inactive_broadcasts = Broadcast.inactive.for(@organization)

    @builds_remaining = Travis::DataStores.redis.get("trial:#{@organization.login}")
    @builds_provided = builds_provided_for(@organization)
  end

  def update_trials
    @organization = Organization.find_by(id: params[:id])
    update_topaz(@organization, params[:builds_remaining])
  end
end
