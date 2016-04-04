module Travis::API::V3
  class Services::Overview::EventType < Service

    def run!
      find(:repository).overview.event_type
    end
  end
end
