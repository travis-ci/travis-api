module Travis::API::V3
  class Services::User::Logout < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      result(access_control.user) if Travis.redis.del("t:#{access_control.token}") == 1
    end
  end
end