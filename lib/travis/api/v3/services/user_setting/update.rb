module Travis::API::V3
  class Services::UserSetting::Update < Service
    params :value, prefix: :setting
    params :value, prefix: :user_setting

    def run!
      repository = check_login_and_find(:repository)
      user_setting = query.update(repository)
      access_control.permissions(user_setting).write!
      result user_setting
    end
  end
end
