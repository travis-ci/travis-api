class OffendersController < ApplicationController
  include ApplicationHelper

  def index
    @offending_users = Offender.users
    @offending_organizations = Offender.organizations
  end

  def update
    @offender = Organization.find_by(login: params[:login]) || User.find_by(login: params[:login])
    Services::Abuse::Update.new(@offender, offender_params, current_user).call

    flash[:notice] = "Abuse settings for #{describe(@offender)} updated."
    redirect_to @offender
  end

  private

  def offender_params
    params.require(:offender).permit(:abuse, :reason, :not_fishy)
  end
end