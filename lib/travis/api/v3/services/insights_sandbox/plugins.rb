module Travis::API::V3
  class Services::InsightsSandbox::Plugins < Service
    params :plugin_type
    result_type :insights_sandbox_plugins

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_sandbox).plugins(access_control.user.id)
    end
  end
end
