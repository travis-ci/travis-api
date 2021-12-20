module Travis::API::V3
  class Services::InsightsNotifications::ToggleSnooze < Service
    params :notification_ids

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_notifications).toggle_snooze(access_control.user.id)
    end
  end
end
