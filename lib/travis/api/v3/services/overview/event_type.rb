module Travis::API::V3
  class Services::Overview::EventType < Service

    def run!
      find(:repository).event_type_overview
    end
  end
end
