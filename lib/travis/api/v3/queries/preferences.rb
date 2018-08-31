module Travis::API::V3
  class Queries::Preferences < Query
    def find(user)
      user.preferences
    end
  end
end
