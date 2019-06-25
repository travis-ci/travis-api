module Users
  class AbuseDetectionsController < ApplicationController
    before_action :fetch_offender, only: [:update]

    def update
      Services::Abuse::Update.new(@offender, offender_params, current_user).call
      flash[:notice] = "Abuse settings updated."
      redirect_to @offender
    end

    private

    def fetch_offender
      @offender = User.find(params[:id])
    end

    def offender_params
      params.permit(:abuse_trusted, :abuse_offenders, :abuse_not_fishy, :abuse_reason)
    end
  end
end