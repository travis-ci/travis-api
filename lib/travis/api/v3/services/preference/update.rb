module Travis::API::V3
  class Services::Preference::Update < Service
    params :value, prefix: :preference

    def run!
      user = access_control.user or raise LoginRequired
      result query.update(user)
    end
  end
end
