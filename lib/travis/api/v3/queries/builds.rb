module Travis::API::V3
  class Queries::Builds < Query
    def find(repository)
      filter(repository.builds)
    end

    def filter(list)
      # filtering by branch, type, etc would go here
      list.includes(:commit).includes(branch: :last_build)
    end
  end
end
