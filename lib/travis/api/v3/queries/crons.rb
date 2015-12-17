module Travis::API::V3
  class Queries::Crons < Query

    def find(branch)
      branch.crons
    end
  end
end
