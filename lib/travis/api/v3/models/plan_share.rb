module Travis::API::V3
  class Models::PlanShare
    attr_reader :plan_id, :donor, :receiver, :shared_by, :created_at, :admin_revoked, :credits_consumed
    def initialize(attributes = {})
      @plan_id = attributes.fetch('plan_id')
      @donor = attributes.fetch('donor')
      @receiver = attributes.fetch('receiver')
      @shared_by = attributes.fetch('shared_by')
      @created_at = attributes.fetch('created_at')
      @admin_revoked = attributes.fetch('admin_revoked')
      @credits_consumed = attributes.fetch('credits_consumed')
    end
  end
end
