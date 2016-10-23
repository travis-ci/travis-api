class JobsController < ApplicationController
  include ApplicationHelper

  def show
    @job = Job.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no job associated with that ID." if @job.nil?

    @log = api.job(@job.id).log.body
  end

  def cancel
    @job = Job.find_by(id: params[:id])

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
    @job = Job.find_by(id: params[:id])

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

  def api
    @api ||= begin
      options = { 'uri' => Travis::Config.load.api_endpoint }
      user    = self.user if respond_to? :user
      user  ||= repository.admin if respond_to? :repository and repository
      options['access_token'] = access_token(user).to_s if user
      Travis::Client.new(options)
    end
  end
end
