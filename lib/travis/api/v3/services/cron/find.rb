module Travis::API::V3
  class Services::Cron::Find < Service
    #params :id

    def run!
      raise InsufficientAccess unless Travis::Features.feature_active?(:cron)
      find
    end
  end
end
