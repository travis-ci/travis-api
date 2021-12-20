module Travis::API::V3
  class Services::InsightsProbes::All < Service
    params :filter, :page, :limit, :active, :sort_by, :sort_direction
    result_type :insights_probes
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_probes).all(access_control.user.id)
    end
  end
end
