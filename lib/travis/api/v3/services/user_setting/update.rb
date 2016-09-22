module Travis::API::V3
  class Services::UserSetting::Update < Service
    params :value, prefix: :setting

    def run!
      repository = check_login_and_find(:repository)
      query.update(repository)
    end
  end
end
