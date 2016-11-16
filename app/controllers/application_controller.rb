require(File.expand_path('../models/user', File.dirname(__FILE__)))

class ApplicationController < ActionController::Base
  include Travis::SSO::Helpers
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  def otp_valid?
    return true if Travis::Config.load.disable_otp? && !Rails.env.production?

    secret = Travis::DataStores.redis.get("admin-v2:otp:#{current_user.login}")
    return ROTP::TOTP.new(secret).verify(params[:otp])
  end
end
