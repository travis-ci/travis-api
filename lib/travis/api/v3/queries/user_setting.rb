module Travis::API::V3
  class Queries::UserSetting < Query
    params :name, :value, prefix: :setting

    def find(repository)
      repository.user_settings.read(name)
    end

    def update(repository)
      repository.user_settings.update(name, value)
    end
  end
end
