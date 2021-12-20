module Travis::API::V3
  class Services::InsightsPlugins::ToggleActive < Service
    params :ids
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).toggle_active(access_control.user.id)
    end
  end
end
