module Travis::API::V3
  class Services::Preference::Find < Service
    def run!
      user = access_control.user or raise LoginRequired
      result query.find(user)
    end
  end
end
