class SettingsController < ApplicationController
  def update
    @repository = Repository.find_by(id: params[:id])

    response = Services::Settings::Update.new(@repository.id, setting_params).call

    if response.success?
      flash[:notice] = "Updates settings for #{@repository.slug}"
    else
      flash[:error] = "Error: #{response.headers[:status]}"
    end

    redirect_to repository_path(anchor: "settings")
  end

  private
    def setting_params
      params.require(:setting).permit(*Settings::PERMITTED)
    end
end
