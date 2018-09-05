module Travis::API::V3
  class Queries::Preferences < Query
    def find(user)
      user.user_preferences
    end
  end
end
