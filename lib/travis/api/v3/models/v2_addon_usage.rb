module Travis::API::V3
  class Models::V2AddonUsage
    attr_reader :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :purchase_date, :valid_to, :active, :status,
                :quantity_limit_free, :quantity_limit_type, :quantity_limit_charge, :total_usage

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
      @quantity_limit_free = attrs.fetch('quantity_limit_free', 0)
      @quantity_limit_type = attrs.fetch('quantity_limit_type', nil)
      @quantity_limit_charge = attrs.fetch('quantity_limit_charge', nil)
      @total_usage = attrs.fetch('total_usage', nil)
    end
  end
end
