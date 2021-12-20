module Travis::API::V3
  class Services::InsightsSandbox::PluginData < Service
    params :plugin_type
    result_type :insights_sandbox_plugin_data

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_sandbox).plugin_data(access_control.user.id)
    end
  end
end
