module Travis::API::V3
  class Models::PlanShare
    attr_reader :plan_id, :donor, :receiver, :shared_by, :created_at
    def initialize(attributes = {})
      @plan_id = attributes.fetch('plan_id')
      @donor = attributes.fetch('donor')
      @receiver = attributes.fetch('receiver')
      @shared_by = attributes.fetch('shared_by')
      @created_at = attributes.fetch('created_at')
    end
  end
end
