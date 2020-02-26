require(File.expand_path('../models/user', File.dirname(__FILE__)))

class ApplicationController < ActionController::Base
  include Travis::SSO::Helpers
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user

  before_action :setup_cache_headers

  def otp_valid?
    return true if travis_config.disable_otp? && !Rails.env.production?

    secret = Travis::DataStores.redis.get("admin-v2:otp:#{current_user.login}")
    return ROTP::TOTP.new(secret).verify(params[:otp])
  end

  def travis_config
    Rails.configuration.travis_config
  end

  private

  def setup_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
