module Travis::API::V3
  class Services::Preference::Update < Service
    params :value, prefix: :preference

    def run!
      owner = access_control.user or raise LoginRequired
      owner = find(:organization) if params['organization.id']
      result query.update(owner) if access_control.adminable?(owner)
    end
  end
end
