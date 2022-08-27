module Travis::API::V3
  class Services::InsightsPlugins::RunScan < Service
    result_type :insights_plugins
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).run_scan(access_control.user.id)
    end
  end
end
