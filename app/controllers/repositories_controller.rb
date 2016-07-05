class RepositoriesController < ApplicationController
  def show
    @repository = Repository.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no repository associated with that ID." if @repository.nil?

    @builds = @repository.builds.includes(:commit).order('id DESC').take(30)
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').take(30)

    @active_broadcasts = Broadcast.active.for(@repository)
    @inactive_broadcasts = Broadcast.inactive.for(@repository)
  end

  def enable
    @repository = Repository.find_by(id: params[:id])

    Services::Repository::Enable.new(@repository.id).call
    redirect_to @repository
  end

  def disable
    @repository = Repository.find_by(id: params[:id])

    Services::Repository::Disable.new(@repository.id).call
    redirect_to @repository
  end
end
