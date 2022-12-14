module Travis::API::V3
  class Models::V2AddonUsage
    attr_reader :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :purchase_date, :valid_to, :active, :status

    def initialize(attrs)
      @id = attrs.fetch('id')
      @addon_id = attrs.fetch('addon_id')
      @addon_quantity = attrs.fetch('addon_quantity')
      @addon_usage = attrs.fetch('addon_usage')
      @remaining = attrs.fetch('remaining')
      @purchase_date = attrs.fetch('purchase_date')
      @valid_to = attrs.fetch('valid_to')
      @active = attrs.fetch('active')
      @status = attrs.fetch('status')
    end
  end
end
