module Travis::API::V3
  class Services::Overview::EventType < Service

    def run!
      model = Models::Overview.new(find(:repository))
      model.event_type
    end
  end
end
