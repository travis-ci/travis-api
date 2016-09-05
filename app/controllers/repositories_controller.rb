class RepositoriesController < ApplicationController
  before_action :get_repository

  def disable
    response = Services::Repository::Disable.new(@repository.id).call

    if response.success?
      flash[:notice] = "Disabled #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  def enable
    response = Services::Repository::Enable.new(@repository.id).call

    if response.success?
      flash[:notice] = "Enabled #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  def features
    Services::Features::Update.new(@repository).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@repository.slug}."
    redirect_to repository_path(@repository, anchor: "settings")
  end

  def show
    return redirect_to root_path, alert: "There is no repository associated with ID #{params[:id]}." if @repository.nil?

    @builds = @repository.builds.includes(:commit).order('id DESC').take(30)
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').take(30)

    @active_broadcasts = Broadcast.active.for(@repository)
    @inactive_broadcasts = Broadcast.inactive.for(@repository)

    @features = Features.for(@repository)
  end

  private

  def get_repository
    @repository = Repository.find_by(id: params[:id])
  end

  def feature_params
    params.require(:features).permit(Features.for(@repository).keys)
  end
end
