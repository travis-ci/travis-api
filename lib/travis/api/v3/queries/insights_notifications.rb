module Travis::API::V3
  class Queries::InsightsNotifications < Query
    params :filter, :page, :limit, :active, :sort_by, :sort_direction

    def all(user_id)
      insights_client(user_id).user_notifications(
        params['filter'],
        params['page'],
        params['active'],
        params['sort_by'],
        params['sort_direction']
      )
    end

    def toggle_snooze(user_id)
      insights_client(user_id).toggle_snooze_user_notifications(params['notification_ids'])
    end

    private

    def insights_client(user_id)
      @_insights_client ||= InsightsClient.new(user_id)
    end
  end
end
