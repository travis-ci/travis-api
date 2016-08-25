class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])
    @settings = Settings.new(settings_params)

    response = Services::Settings::Update.new(@repository.id, @settings.as_json).call

    if response.success?
      flash[:notice] = "Updates settings for #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to repository_path(anchor: "settings")
  end

  private
    def settings_params
      params.require(:settings).permit(*Settings::BINARY, *Settings::INTEGER)
    end
end
