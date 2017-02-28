module Travis::API::V3
  class Services::Accounts::ForCurrentUser < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      result query.for_member(access_control.user)
    end
  end
end
