module Travis::API::V3
  class Models::AutoRefill

    attr_reader :addon_id, :enabled, :threshold, :amount
    def initialize(attributes = {})
      @addon_id = attributes.fetch('addon_id', nil) || attributes.fetch('id', nil)
      @enabled = attributes.key?('enabled') ? attributes.fetch('enabled') : true
      @threshold = attributes.key?('refill_threshold') ? attributes.fetch('refill_threshold') : 25000
      @amount = attributes.key?('refill_amount') ? attributes.fetch('refill_amount'): 10000
    end
  end

end
