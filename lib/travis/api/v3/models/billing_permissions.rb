module Travis::API::V3
  class Models::BillingPermissions
    def initialize(attrs = {})
      @read = attrs.fetch('read')
      @write = attrs.fetch('write')
    end

    def read?
      @read
    end

    def write?
      @write
    end
  end
end
