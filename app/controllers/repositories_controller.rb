class RepositoriesController < ApplicationController
  def show
    @repository = Repository.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no repository associated with ID #{params[:id]}." if @repository.nil?

    @builds = @repository.builds.includes(:commit).order('id DESC').take(30)
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').take(30)

    @active_broadcasts = Broadcast.active.for(@repository)
    @inactive_broadcasts = Broadcast.inactive.for(@repository)
  end

  def enable
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Enable.new(@repository.id).call

    if response.success?
      flash[:notice] = "Enabled #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  def disable
    @repository = Repository.find_by(id: params[:id])

    response = Services::Repository::Disable.new(@repository.id).call

    if response.success?
      flash[:notice] = "Disabled #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end
end
