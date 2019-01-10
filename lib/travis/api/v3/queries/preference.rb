module Travis::API::V3
  class Queries::Preference < Query
    params :name, :value, prefix: :preference

    def find(owner)
      owner.preferences.read(name)
    end

    def update(owner)
      owner.preferences.update(name, value)
    end
  end
end
