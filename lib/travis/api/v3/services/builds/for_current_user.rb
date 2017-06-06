module Travis::API::V3
  class Services::Builds::ForCurrentUser < Service
    # params :active, prefix: :broadcast
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      result query.for_user(access_control.user)
    end
  end
end