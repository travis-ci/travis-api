class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @repositories = @user.repositories

    @current_jobs = Job.from_repositories(@repositories)
                       .not_finished_sorted
  end
end
