module Travis::API::V3
  class Services::InsightsProbes::DeleteMany < Service
    params :ids

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query(:insights_probes).delete_many(access_control.user.id)
      no_content
    end
  end
end
