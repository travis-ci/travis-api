module Travis::API::V3
  class Queries::SpotlightSummary < Query
    params :time_start, :time_end, :repo_id, :build_status

    def all(user_id)
      insights_client(user_id).spotlight_summary(
        params['time_start'],
        params['time_end'],
        params['repo_id'],
        params['build_status']
      )
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
