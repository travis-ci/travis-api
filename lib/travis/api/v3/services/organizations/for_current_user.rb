module Travis::API::V3
  class Services::Organizations::ForCurrentUser < Service
    params :role, prefix: :organization
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      result query.for_member(access_control.user)
    end
  end
end
