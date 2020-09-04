module Travis::API::V3
  class Models::V2AddonUsage
    attr_reader :id, :addon_id, :addon_quantity, :addon_usage, :remaining, :active

    def initialize(attrs)
      @id = attrs.fetch('id')
      @addon_id = attrs.fetch('addon_id')
      @addon_quantity = attrs.fetch('addon_quantity')
      @addon_usage = attrs.fetch('addon_usage')
      @remaining = attrs.fetch('remaining')
      @active = attrs.fetch('active')
    end
  end
end
