class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no user associated with that ID." if @user.nil?

    @repositories = @user.permitted_repositories

    @pending_jobs = Job.from_repositories(@repositories).not_finished
    @finished_jobs = Job.from_repositories(@repositories).finished.take(10)

    @active_broadcasts = Broadcast.active.for(@user)
    @inactive_broadcasts = Broadcast.inactive.for(@user)
  end
end
