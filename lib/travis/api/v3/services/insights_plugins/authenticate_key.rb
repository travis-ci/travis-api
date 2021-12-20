module Travis::API::V3
  class Services::InsightsPlugins::AuthenticateKey < Service
    params :plugin_type, :public_id, :private_key, :app_key, :domain, :key_hash
    result_type :insights_plugin_authenticate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).authenticate_key(access_control.user.id)
    end
  end
end
