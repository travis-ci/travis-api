class RepositoriesController < ApplicationController
  before_action :get_repository

  def disable
    response = Services::Repository::Disable.new(@repository).call

    if response.success?
      flash[:notice] = "Disabled #{@repository.slug}"
      Services::AuditTrail::DisableRepository.new(current_user, @repository).call
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  def enable
    response = Services::Repository::Enable.new(@repository).call

    if response.success?
      flash[:notice] = "Enabled #{@repository.slug}"
      Services::AuditTrail::EnableRepository.new(current_user, @repository).call
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  def features
    Services::Features::Update.new(@repository, current_user).call(feature_params)
    flash[:notice] = "Updated feature flags for #{@repository.slug}."
    redirect_to repository_path(@repository, anchor: "settings")
  end

  def show
    # there is a bug, so that .includes(:subscription) is not working and we get N+1 queries for subscriptions,
    # this is a workaround to get all the subscriptions at once and avoid the N+1 queries (see issue #150)
    @subscriptions = Subscription.where(owner_id: @repository.users.map(&:id)).where('owner_type = ?', 'User').includes(:owner)
    @subscriptions_by_user_id = @subscriptions.group_by { |s| s.owner.id }

    @builds = @repository.builds.includes(:commit).order('id DESC').take(30)
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').take(30)

    @active_broadcasts = Broadcast.active.for(@repository).includes(:recipient)
    @inactive_broadcasts = Broadcast.inactive.for(@repository).includes(:recipient)

    @features = Features.for(@repository)
  end

  private

  def get_repository
    @repository = Repository.find_by(id: params[:id])
    return redirect_to root_path, alert: "There is no repository associated with ID #{params[:id]}." if @repository.nil?
  end

  def feature_params
    params.require(:features).permit(Features.for(@repository).keys)
  end

  def settings
  end
end
