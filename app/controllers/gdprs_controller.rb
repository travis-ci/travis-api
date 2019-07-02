class GdprsController < ApplicationController
  before_action :get_user

  def export
    client = ::Services::Gdpr::Client.new(@user)
    client.export
    flash[:notice] = "Triggered user data export for user #{@user.login}"
    redirect_back(fallback_location: root_path)
  end

  def purge
    client = ::Services::Gdpr::Client.new(@user)
    client.purge
    flash[:notice] = "Triggered user data purge for user #{@user.login}"
    redirect_back(fallback_location: root_path)
  end

  def confirmation

  end

  private

  def get_user
    @user = User.find_by(id: params[:id])
    redirect_to not_found_path, flash: { error: "There is no user associated with ID #{params[:id]}." } if @user.nil?
  end
end