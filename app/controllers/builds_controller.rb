class BuildsController < ApplicationController
  def show
    @build = Build.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no build associated with that ID." if @build.nil?

    @jobs = @build.jobs.includes(:repository)
  end

  def cancel
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Cancel.new(@job.id).call

    if response.success?
      flash[:notice] = "Build successfully canceled."
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @build
  end

  def restart
    @build = Build.find_by(id: params[:id])

    response = Services::Build::Restart.new(@build.id).call

    if response.success?
      flash[:notice] = "Build successfully restarted."
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @build
  end
end
