class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])
    current_settings = Settings.new(@repository.settings)
    settings = Settings.new(settings_params)

    settings.attributes.each do |setting_name, setting_value|
      if current_settings.attributes[setting_name] != setting_value
        response = Services::Settings::Update.new(@repository.id, setting_name, setting_value).call

        if response.success?
          flash[:notice] = "Updated settings for #{@repository.slug}"
        else
          flash[:error] = "Error: #{response.headers[:status]}"
          return
        end
      end
    end

    redirect_to @repository
  end

  private

  def settings_params
    params.require(:settings).permit(*Settings::BINARY, *Settings::INTEGER)
  end
end
