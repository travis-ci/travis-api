module AuthHelper
  def admin_login
    username, password = ENV['ADMIN_NAME'], ENV['ADMIN_PASSWORD']
    @request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
