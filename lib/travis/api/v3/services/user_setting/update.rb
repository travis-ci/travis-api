module Travis::API::V3
  class Services::UserSetting::Update < Service
    type :setting
    params :value, prefix: :setting

    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      user_setting = query.find(repository)
      access_control.permissions(user_setting).write! if user_setting
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token).app_id

      user_setting = query.update(repository, access_control.user, app_id == 2)
      result user_setting
    end
  end
end
