module Travis::API::V3
  class Services::UserSetting::Update < Service
    type :setting
    params :value, prefix: :setting

    def run!
      puts "DEBUG_ME: jestem tu"
      repository = check_login_and_find(:repository)
      puts "DEBUG_ME: repository: #{repository.inspect}"
      user_setting = query.update(repository)
      puts "DEBUG_ME: user_setting: #{user_setting.inspect}"
      return repo_migrated if migrated?(repository)
      puts "DEBUG_ME: access_control: #{access_control.inspect}"
      access_control.permissions(user_setting).write!
      result user_setting
    end
  end
end
