module Travis::API::V3
  class Renderer::InsightsProbes < CollectionRenderer
    type           :tests
    collection_key :tests
  end
end
