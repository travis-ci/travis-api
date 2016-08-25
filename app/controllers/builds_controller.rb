class BuildsController < ApplicationController
  include ApplicationHelper

  def show
    @build = Build.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no build associated with that ID." if @build.nil?

    @jobs = @build.jobs.includes(:repository)
  end

  def cancel
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Cancel.new(@build.id).call

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = "Build #{describe(@build)} successfully canceled."
        else
          flash[:error] = "Error: #{response.headers[:status]}"
        end

        redirect_to @build
      end

      format.json do
        if response.success?
          render json: {"success": true,
            "message": "Build #{describe(@build)} successfully canceled."}
        else
          render json: {"success": false,
            "message": "Error: #{response.headers[:status]}"}
        end
      end
    end
  end

  def restart
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Restart.new(@build.id).call

    respond_to do |format|
      format.html do
        if response.success?
          flash[:notice] = "Build #{describe(@build)} successfully restarted."
        else
          flash[:error] = "Error: #{response.headers[:status]}"
        end

        redirect_to @build
      end

      format.json do
        if response.success?
          render json: {"success": true,
            "message": "Build #{describe(@build)} successfully restarted."}
        else
          render json: {"success": false,
            "message": "Error: #{response.headers[:status]}"}
        end
      end
    end
  end
end
