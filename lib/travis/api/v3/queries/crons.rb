module Travis::API::V3
  class Queries::Crons < Query

    def find(repository)
      repository.crons
    end
  end
end
