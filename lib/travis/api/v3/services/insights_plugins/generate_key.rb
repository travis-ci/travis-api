module Travis::API::V3
  class Services::InsightsPlugins::GenerateKey < Service
    params :plugin_name, :plugin_type
    result_type :insights_plugin_key

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).generate_key(access_control.user.id)
    end
  end
end
