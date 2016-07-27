class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])
    @setting = Setting.new(@repository).get

    response = Services::Setting::Update.new(@repository.id, setting_params).call

    if response.success?
      flash[:notice] = "Updates settings for #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to @repository
  end

  private
    def setting_params
      params.require(:setting).permit(
        "builds_only_with_travis_yml", "build_pushes", "build_pull_requests",
        "maximum_number_of_builds"
        )
    end
end
