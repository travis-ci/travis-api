module Travis::API::V3
  class Queries::SpotlightSummaryRepos < Query
    def all(user_id)
      insights_client(user_id).spotlight_summary_repos
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
