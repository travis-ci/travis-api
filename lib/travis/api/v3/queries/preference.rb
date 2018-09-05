module Travis::API::V3
  class Queries::Preference < Query
    params :name, :value, prefix: :preference

    def find(user)
      user.user_preferences.read(name)
    end

    def update(user)
      user.user_preferences.update(name, value)
    end
  end
end
