class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @repositories = @user.repositories

    @current_jobs = Job.not_finished
                       .from_repositories(@repositories)
                       .sort_by do |job|
                         %w[started received queued created].index(job.state.to_s)
                       end
  end
end
