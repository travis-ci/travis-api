module Travis::API::V3
  class Services::UserSetting::Update < Service
    type :setting
    params :value, prefix: :setting

    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)
      
      user_setting = query.find(repository)
      access_control.permissions(user_setting).write!
      
      user_setting = query.update(repository)      
      result user_setting
    end
  end
end
