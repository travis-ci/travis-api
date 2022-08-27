module Travis::API::V3
  class Queries::InsightsSandbox < Query
    params :plugin_type, :plugin_id, :query

    def plugins(user_id)
      insights_client(user_id).sandbox_plugins(params['plugin_type'])
    end

    def plugin_data(user_id)
      insights_client(user_id).sandbox_plugin_data(params['plugin_id'])
    end

    def run_query(user_id)
      insights_client(user_id).sandbox_run_query(params['plugin_id'], params['query'])
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
