module Travis::API::V3
  class Services::InsightsSandbox::RunQuery < Service
    params :plugin_id, :query
    result_type :insights_sandbox_query_result

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_sandbox).run_query(access_control.user.id)
    end
  end
end
