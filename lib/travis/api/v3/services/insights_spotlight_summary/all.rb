module Travis::API::V3
    class Services::InsightsSpotlightSummary::All < Service
      params :time_start, :time_end, :repo_id, :build_status
      result_type :insights_spotlight_summary
  
      def run!
        raise LoginRequired unless access_control.full_access_or_logged_in?
        result query(:insights_spotlight_summary).all(access_control.user.id)
      end
    end
  end
  