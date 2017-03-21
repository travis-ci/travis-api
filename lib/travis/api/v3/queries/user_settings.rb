module Travis::API::V3
  class Queries::UserSettings < Query
    def find(repo)
      repo.user_settings
    end
  end
end
