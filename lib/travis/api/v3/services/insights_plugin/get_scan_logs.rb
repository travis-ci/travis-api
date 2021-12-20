module Travis::API::V3
  class Services::InsightsPlugin::GetScanLogs < Service
    params :plugin_id, :last_id
    result_type :insights_plugin_scan_logs

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).get_scan_logs(access_control.user.id)
    end
  end
end
