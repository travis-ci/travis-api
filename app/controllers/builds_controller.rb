class BuildsController < ApplicationController
  include ApplicationHelper

  before_action :get_build

  def show
    @jobs = @build.jobs.includes(:repository)
  end

  def cancel
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

  private

  def get_build
    @build = Build.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no build associated with ID #{params[:id]}."} if @build.nil?
  end
end
