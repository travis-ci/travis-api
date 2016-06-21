class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no User for that ID" if @user.nil?

    @repositories = @user.permitted_repositories
    @pending_jobs = Job.from_repositories(@repositories).not_finished
  end
end
