module Travis::API::V3
  class Queries::InsightsPublicKey < Query
    def latest(user_id)
      insights_client(user_id).public_key
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
