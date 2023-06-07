module Travis::API::V3
  class Services::UserSetting::Find < Service
    def run!
      repository = check_login_and_find(:repository)

      access_control.permissions(repository).settings_read!
      result find(:user_setting, repository)
    end
  end
end
