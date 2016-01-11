module Travis::API::V3
  class Services::Cron::ForBranch < Service

    def run!
      Models::Cron.where(:branch_id => find(:branch, find(:repository))).first
    end
  end
end
