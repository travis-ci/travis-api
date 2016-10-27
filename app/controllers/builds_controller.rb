class BuildsController < ApplicationController
  include ApplicationHelper

  def show
    @build = Build.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no build associated with that ID." if @build.nil?

    @jobs = @build.jobs.includes(:repository)
  end

  def cancel
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Cancel.new(@build).call

    if response.success?
      message = "Build #{describe(@build)} successfully canceled."
      Services::AuditTrail::CancelBuild.new(current_user, @build).call
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

        redirect_to @build
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
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Restart.new(@build).call

    if response.success?
      message = "Build #{describe(@build)} successfully restarted."
      Services::AuditTrail::RestartBuild.new(current_user, @build).call
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

        redirect_to @build
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
