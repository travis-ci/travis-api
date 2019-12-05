module Travis::API::V3
  class Models::JobsStats
    attr_reader :started, :queued

    def initialize(attributes = {})
      @started = attributes.fetch('started') { 0 }
      @queued = attributes.fetch('queued') { 0 }
    end
  end
end
