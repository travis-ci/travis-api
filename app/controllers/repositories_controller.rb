class RepositoriesController < ApplicationController
  before_action :get_repository

  def add_hook_event
    Services::Repository::AddHookEvent.new(@repository, params[:event], hook_link).call
    Services::AuditTrail::AddHookEvent.new(current_user, @repository, params[:event].gsub('_', ' ')).call
    flash[:notice] = "Added #{params[:event].gsub('_', ' ')} event to #{@repository.slug}."
    redirect_to @repository
  end

  def builds
    @builds = @repository.builds.includes(:commit).order('id DESC').paginate(page: params[:build_page], per_page: 10)
  end

  def check_hook
    case
    when hook.nil?
      flash[:error] = 'No hook found on GitHub.'
      redirect_to @repository
    when hook['active'] != @repository.active?
      render :check_hook
    when !hook['events'].include?('pull_request')
      @event = 'pull_request'
      render :check_hook
    when !hook['events'].include?('push')
      @event = 'push'
      render :check_hook
    when hook_url != hook_url(Travis::Config.load.service_hook_url)
      @hook_url = hook_url(hook['config']['domain'])
    else
      flash[:notice] = 'That hook seems legit.'
      redirect_to @repository
    end
  end

  def delete_last_build
    if otp_valid?
      keys       = @repository.attributes.keys.select { |k| k.start_with? 'last_build_' }
      attributes = Hash[keys.each_with_object(nil).to_a]
      @repository.update_attributes!(attributes)

      flash[:notice] = "Dropped last build reference."
      Services::AuditTrail::DeleteLastBuild.new(current_user, @repository).call
    else
      flash[:error] = "One time password did not match, please try again."
    end
    redirect_to @repository
  end

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

  def requests
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').paginate(page: params[:request_page], per_page: 10)
  end

  def set_hook_url
    config = hook['config'].merge('domain' => hook_url(Travis::Config.load.service_hook_url))
    Services::Repository::SetHookUrl.new(@repository, config, hook_link).call
    Services::AuditTrail::SetHookUrl.new(current_user, @repository, Travis::Config.load.service_hook_url).call
    flash[:notice] = "Set notification target to #{Travis::Config.load.service_hook_url}."
    redirect_to @repository
  end

  def show
    @active_admin = @repository.find_admin
    @users = @repository.users.select('users.*, permissions.admin as admin, permissions.push as push, permissions.pull as pull').order(:name)

    @builds = @repository.builds.includes(:commit).order('id DESC').paginate(page: params[:build_page], per_page: 10)
    @requests = @repository.requests.includes(builds: :repository).order('id DESC').paginate(page: params[:request_page], per_page: 10)

    @active_broadcasts = Broadcast.active.for(@repository).includes(:recipient)
    @inactive_broadcasts = Broadcast.inactive.for(@repository).includes(:recipient)

    @features = Features.for(@repository)

    @settings = Settings.new(@repository.settings)

    @caches = Services::Repository::Caches::FindAll.new(@repository).call
  end

  def test_hook
    Services::Repository::TestHook.new(@repository, hook["_links"]["test"]["href"]).call
    flash[:notice] = 'Test hook fired.'
    redirect_to @repository
  end

  private

  def get_repository
    @repository = Repository.find_by(id: params[:id])
    return redirect_to not_found_path, flash: {error: "There is no repository associated with ID #{params[:id]}."} if @repository.nil?
  end

  def feature_params
    params.require(:features).permit(Features.for(@repository).keys)
  end

  def hook
    @hook ||= Services::Repository::CheckHook.new(@repository).call
  end

  def hook_url(domain = hook['config']['domain'])
    return "https://notify.travis-ci.org" unless domain
    domain =~ /^https?:/ ? domain : "https://#{domain}"
  end

  def hook_link
    hook["_links"]["self"]["href"]
  end
end
