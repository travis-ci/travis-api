module Travis::API::V3
  class Services::AccessToken::RemoveToken < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token)&.app_id
      query.remove_token(access_control.user, access_control.token, app_id)
      deleted
    end
  end
end
