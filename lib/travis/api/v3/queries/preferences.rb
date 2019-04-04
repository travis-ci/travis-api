module Travis::API::V3
  class Queries::Preferences < Query
    def find(owner)
      owner.preferences
    end
  end
end
