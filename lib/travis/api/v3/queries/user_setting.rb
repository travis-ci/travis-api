module Travis::API::V3
  class Queries::UserSetting < Query
    params :name, prefix: :setting

    def find(repo)
      repo.user_settings.setting(name)
    end
  end
end
