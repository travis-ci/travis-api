module Users
  class AbuseDetectionsController < ApplicationController
    before_action :fetch_offender, only: [:update]

    def update
      Services::Abuse::Update.new(@offender, offender_params, current_user).call
      redirect_to @offender
    end

    private

    def fetch_offender
      @offender = User.find(params[:id])
    end

    def offender_params
      params.require(:abuse).permit(:trusted, :offenders, :not_fishy, :reason)
    end
  end
end