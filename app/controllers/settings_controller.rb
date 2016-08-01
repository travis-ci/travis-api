class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])

    response = Services::Settings::Update.new(@repository.id, settings_params).call

    if response.success?
      flash[:notice] = "Updates settings for #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to repository_path(anchor: "settings")
  end

  private
    def settings_params
      params.require(:settings).permit(*Settings::PERMITTED)
    end
end
