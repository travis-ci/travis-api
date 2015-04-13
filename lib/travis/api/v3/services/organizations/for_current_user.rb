module Travis::API::V3
  class Services::Organizations::ForCurrentUser < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      query.for_member(access_control.user)
    end
  end
end
