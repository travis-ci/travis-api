class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])
    current_settings = Settings.new(@repository.settings)
    settings = Settings.new(settings_params)
    not_in_api = %w[timeout_hard_limit timeout_log_silence api_build_rate_limit]

    if settings.valid?
      settings.attributes.except(*not_in_api).each do |setting_name, setting_value|
        if current_settings.attributes[setting_name] != setting_value
          response = Services::Settings::Update.new(@repository, setting_name, setting_value).call
          if response.success?
            flash[:notice] = "Updated settings for #{@repository.slug}"
          else
            flash[:error] = "Error: #{response.headers[:status]}"
            break
          end
        end
      end

      settings.attributes.slice(*not_in_api).each do |setting_name, setting_value|
        if current_settings.attributes[setting_name] != setting_value
          @repository.settings[setting_name] = setting_value.to_i
          @repository.update!(settings: @repository.settings)
          flash[:notice] = "Updated settings for #{@repository.slug}"
        end
      end
    else
      flash[:warning] = settings.errors
    end
    redirect_to @repository
  end

  private

  def settings_params
    params.require(:settings).permit(*Settings::BINARY, *Settings::INTEGER)
  end
end