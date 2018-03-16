module Travis::API::V3
  class Models::Subscription < Struct.new(:id)
    def initialize(attributes = {})
      super(attributes.fetch('id'))
    end
  end
end
