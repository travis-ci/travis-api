module Travis::API::V3
  class Services::InsightsPlugins::DeleteMany < Service
    params :ids
    result_type :insights_plugins
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_plugins).delete_many(access_control.user.id)
    end
  end
end
