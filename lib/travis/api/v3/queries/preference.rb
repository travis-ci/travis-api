module Travis::API::V3
  class Queries::Preference < Query
    params :name, :value, prefix: :preference

    def find(user)
      user.preferences.read(name)
    end

    def update(user)
      user.preferences.update(name, value)
    end
  end
end
