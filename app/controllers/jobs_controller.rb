class JobsController < ApplicationController
  def show
    @job = Job.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no job associated with that ID." if @job.nil?
  end

  def cancel
    @job = Job.find_by(id: params[:id])

    response = Services::Job::Cancel.new(@job.id).call

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = "Job successfully canceled."
        else
          flash[:error] = "Error: #{response.headers[:status]}"
        end

        redirect_to @job
      end

      format.json do
        if response.success?
          render json: {"success": true,
            "message": "Job successfully canceled."}
        else
          render json: {"success": false,
            "message": "Error: #{response.headers[:status]}"}
        end
      end
    end
  end

  def restart
    @job = Job.find_by(id: params[:id])

    response = Services::Job::Restart.new(@job.id).call

    if response.success?
      flash[:notice] = 'Job successfully restarted.'
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @job
  end
end
