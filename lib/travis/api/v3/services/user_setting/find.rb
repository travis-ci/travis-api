module Travis::API::V3
  class Services::UserSetting::Find < Service
    def run!
      repository = check_login_and_find(:repository)
      user_setting = find(:user_setting, repository)
      access_control.permissions(user_setting).read!
      user_setting
    end
  end
end
