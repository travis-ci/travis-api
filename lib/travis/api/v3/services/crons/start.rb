module Travis::API::V3
  class Services::Crons::Start < Service

    def run!
      raise InsufficientAccess unless Travis::Features.feature_active?(:cron)
      query.start_all()
    end

  end
end
