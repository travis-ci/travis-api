module Travis::API::V3
  class Models::BulkChangeResult
    ATTRS = %w[changeed skipped]

    attr_accessor :changed, :skipped

    def initialize(attrs)
      @changed = attrs[:changed]
      @skipped = attrs[:skipped]
    end
  end
end
