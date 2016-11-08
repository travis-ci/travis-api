class JobsController < ApplicationController
  include ApplicationHelper

  before_action :get_job

  def show
    @log = Services::Job::GetLog.new(@job).call

    @previous_job = Job.from_build(@job.build).where("id < ?", @job.id).last
    @next_job     = Job.from_build(@job.build).where("id > ?", @job.id).first
  end

  def cancel
    response = Services::Job::Cancel.new(@job).call

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
    response = Services::Job::Restart.new(@job).call

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

  private

  def get_job
    @job = Job.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no job associated with ID #{params[:id]}."} if @job.nil?
  end
end
