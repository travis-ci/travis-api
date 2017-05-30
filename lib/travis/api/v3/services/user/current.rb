module Travis::API::V3
  class Services::User::Current < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      result(access_control.user || not_found(false))
    end
  end
end
