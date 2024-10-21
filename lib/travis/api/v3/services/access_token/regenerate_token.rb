module Travis::API::V3
  class Services::AccessToken::RegenerateToken < Service
    params :token

    def run!
      raise LoginRequired unless access_control.logged_in?
      app_id = Travis::Api::App::AccessToken.find_by_token(params['token'])&.app_id || 0
      result query.regenerate_token(access_control.user, params['token'], app_id, expires_in: Travis::Api::App::AccessToken.auth_token_expires_in)
    end
  end
end
