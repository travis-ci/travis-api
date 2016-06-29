class JobsController < ApplicationController
  def show
    @job = Job.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no job associated with that ID." if @job.nil?
  end
end
