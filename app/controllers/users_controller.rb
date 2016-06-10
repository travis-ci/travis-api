class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @repositories = @user.repositories
    @current_jobs = Job.where(repository_id: @repositories.map(&:id),
                      state: %w[started received queued created])
               .sort_by do |job|
                 %w[started received queued created].index(job.state.to_s)
               end
  end
end
