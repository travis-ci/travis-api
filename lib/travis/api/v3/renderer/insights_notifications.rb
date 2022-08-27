module Travis::API::V3
  class Renderer::InsightsNotifications < CollectionRenderer
    type           :notifications
    collection_key :notifications
  end
end
