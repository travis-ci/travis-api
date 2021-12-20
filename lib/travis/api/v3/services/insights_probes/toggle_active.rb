module Travis::API::V3
  class Services::InsightsProbes::ToggleActive < Service
    params :ids

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query(:insights_probes).toggle_active(access_control.user.id)
      no_content
    end
  end
end
