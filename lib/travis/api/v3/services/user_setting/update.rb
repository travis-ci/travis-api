module Travis::API::V3
  class Services::UserSetting::Update < Service
    type :setting
    params :value, prefix: :setting

    def run!
      repository = check_login_and_find(:repository)
      access_control.permissions(repository).update_settings!
      user_setting = query.update(repository)
      return repo_migrated if migrated?(repository)
      access_control.permissions(user_setting).write!
      result user_setting
    end
  end
end
