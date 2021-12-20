module Travis::API::V3
  class Models::InsightsTag
    attr_reader :name

    def initialize(attributes = {})
      @name = attributes.fetch('name')
    end
  end
end
