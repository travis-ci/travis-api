module Travis::API::V3
  class Queries::UserSettings < Query
    def find(repository)
      repository.user_settings
    end
  end
end
