module Travis::API::V3
  class Services::InsightsPlugins::TemplatePluginTests < Service
    params :plugin_type, :public_id, :private_key, :app_key, :domain, :key_hash
    result_type :insights_plugin_tests

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).template_plugin_tests(access_control.user.id)
    end
  end
end
