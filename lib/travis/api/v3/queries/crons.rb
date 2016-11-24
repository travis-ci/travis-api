module Travis::API::V3
  class Queries::Crons < Query
    def find(repository)
      Models::Cron.where(branch_id: repository.branches)
    end
  end
end
