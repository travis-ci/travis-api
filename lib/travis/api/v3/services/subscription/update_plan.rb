module Travis::API::V3
  class Services::Subscription::UpdatePlan < Service
    params :plan

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      query.update_plan(access_control.user.id)
      no_content
    end
  end
end
