module Travis::API::V3
  class Services::Cron::ForBranch < Service

    def run!
      raise InsufficientAccess unless Travis::Features.feature_active?(:cron)
      query.find_for_branch(find(:branch, find(:repository)))
    end
  end
end
