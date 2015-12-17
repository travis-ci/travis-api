module Travis::API::V3
  class Services::Crons::ForRepository < Service
    paginate

    def run!
      Models::Cron.where(:branch_id => find(:repository).branches)
    end
  end
end
