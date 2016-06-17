class OrganizationsController < ApplicationController
  def show
    @organization = Organization.find(params[:id])
    @repositories = @organization.repositories
    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @users = @organization.users
  end
end
