module Travis::API::V3
  class Models::JobsStats
    attr_reader :started, :queued, :queue_name

    def initialize(attributes = {}, queue_name)
      @started = attributes.fetch('started') { 0 }
      @queued = attributes.fetch('queued') { 0 }
      @queue_name = queue_name
    end
  end
end
