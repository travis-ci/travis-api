class JobsController < ApplicationController
  include ApplicationHelper

  def show
    @job = Job.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no job associated with that ID." if @job.nil?
  end

  def cancel
    @job = Job.find_by(id: params[:id])

    response = Services::Job::Cancel.new(@job.id).call

    if response.success?
      message = "Job #{describe(@job)} successfully canceled."
      Services::AuditTrail::CancelJob.new(current_user, @job).call
    else
      message = "Error: #{response.headers[:status]}"
    end

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = message
        else
          flash[:error] = message
        end

        redirect_to @job
      end

      format.json do
        if response.success?
          render json: {"success": true, "message": message}
        else
          render json: {"success": false, "message": message}
        end
      end
    end
  end

  def restart
    @job = Job.find_by(id: params[:id])

    response = Services::Job::Restart.new(@job.id).call

    if response.success?
      message = "Job #{describe(@job)} successfully restarted."
      Services::AuditTrail::RestartJob.new(current_user, @job).call
    else
      message = "Error: #{response.headers[:status]}"
    end

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = message
        else
          flash[:error] = message
        end

        redirect_to @job
      end

      format.json do
        if response.success?
          render json: {"success": true, "message": message}
        else
          render json: {"success": false, "message": message}
        end
      end
    end
  end
end
