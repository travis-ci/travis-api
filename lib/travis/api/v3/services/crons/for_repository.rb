module Travis::API::V3
  class Services::Crons::ForRepository < Service
    paginate

    def run!
      raise InsufficientAccess unless Travis::Features.feature_active?(:cron)
      query.find(find(:repository))
    end
  end
end
