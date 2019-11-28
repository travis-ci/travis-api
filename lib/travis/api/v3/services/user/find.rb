module Travis::API::V3
  class Services::User::Find < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      result find
    end
  end
end
