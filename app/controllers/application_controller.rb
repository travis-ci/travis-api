require_relative '../models/user'

class ApplicationController < ActionController::Base
  include Travis::SSO::Helpers
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
end
