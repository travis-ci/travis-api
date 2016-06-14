class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @repositories = @user.repositories
    @pending_jobs = Job.from_repositories(@repositories).not_finished
  end
end
