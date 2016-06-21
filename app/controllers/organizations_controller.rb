class OrganizationsController < ApplicationController
  def show
    @organization = Organization.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no Organization for that ID" if @organization.nil?

    @repositories = @organization.repositories
    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @users = @organization.users
  end
end
