module Travis::API::V3
  class Queries::Crons < Query

    def find(branch)
      branch.cron
    end
  end
end
