class RepositoriesController < ApplicationController
  def show
    @repository = Repository.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no repository associated with that ID." if @repository.nil?

    @builds = @repository.builds.includes(:commit).order('id DESC')
    @requests = @repository.requests.includes(:builds).order('id DESC')
  end
end
