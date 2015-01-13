module Travis::API::V3
  class Result
    attr_accessor :resource

    def initialize(resource = nil)
      @resource = resource
    end
  end
end
