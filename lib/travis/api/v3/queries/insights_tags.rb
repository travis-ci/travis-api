module Travis::API::V3
  class Queries::InsightsTags < Query
    def search_tags(user_id)
      insights_client(user_id).search_tags
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
