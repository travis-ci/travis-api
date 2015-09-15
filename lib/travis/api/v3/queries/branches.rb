module Travis::API::V3
  class Queries::Branches < Query
    def find(repository)
      repository.branches
    end
  end
end
