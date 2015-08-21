module Travis::API::V3
  class Queries::Builds < Query
    def find(repository)
      repository.builds
    end
  end
end
