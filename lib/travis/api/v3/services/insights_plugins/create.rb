module Travis::API::V3
  class Services::InsightsPlugins::Create < Service
    params :key_hash, :name, :plugin_type, :public_id, :private_key, :account_name, :app_key, :domain, :sub_plugin
    result_type :insights_plugin

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).create(access_control.user.id)
    end
  end
end
