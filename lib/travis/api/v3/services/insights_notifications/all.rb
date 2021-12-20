module Travis::API::V3
  class Services::InsightsNotifications::All < Service
    params :filter, :page, :limit, :active, :sort_by, :sort_direction
    paginate

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_notifications).all(access_control.user.id)
    end
  end
end
