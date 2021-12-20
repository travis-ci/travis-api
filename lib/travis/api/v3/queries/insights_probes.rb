module Travis::API::V3
  class Queries::InsightsProbes < Query
    params :filter, :page, :limit, :active, :sort_by, :sort_direction, :ids,
      :test_template_id, :test, :plugin_type,
      :notification, :description, :description_link, :type, :labels, :tag_list

    def all(user_id)
      insights_client(user_id).probes(
        params['filter'],
        params['page'],
        params['active'],
        params['sort_by'],
        params['sort_direction']
      )
    end

    def create(user_id)
      insights_client(user_id).create_probe(params)
    end

    def update(user_id)
      insights_client(user_id).update_probe(params)
    end

    def toggle_active(user_id)
      insights_client(user_id).toggle_active_probes(params['ids'])
    end

    def delete_many(user_id)
      insights_client(user_id).delete_many_probes(params['ids'])
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
