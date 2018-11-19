module Travis::API::V3
  class Services::Insights::InsightsProxy < ProxyService
    def run!
      check_owner_class
      raise InsufficientAccess unless Travis.config.org? || access_control.adminable?(owner)
      proxy!
    end

    private

    def owner
      @_owner ||= owner_class.find(params['owner_id'])
    end

    OWNER_CLASSES = {
      'Organization' => Models::Organization,
      'User' => Models::User
    }

    def owner_class
      OWNER_CLASSES.fetch(params['owner_type']) { raise ClientError, 'owner_type must be either User or Organization' }
    end

    alias_method :check_owner_class, :owner_class
  end
end
