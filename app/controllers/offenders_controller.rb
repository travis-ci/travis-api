class OffendersController < ApplicationController
  include ApplicationHelper

  def index
    @offending_users = Offender.users
    @offending_organizations = Offender.organizations
  end

  def update
    @offender = Organization.find_by(login: offender_params[:login]) || User.find_by(login: offender_params[:login])

    Services::Abuse::Update.new(offender_params).call

    flash[:notice] = "Abuse settings for #{describe(@offender)} updated."
    redirect_to :controller => @offender.class.to_s.downcase.pluralize, :action => 'show', :id => @offender, anchor: "account"
  end

  private
    def offender_params
      params.require(:offender).permit(:login, *Offender::LISTS.keys)
    end
end
