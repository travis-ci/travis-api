module Travis::API::V3
  class Renderer::InsightsPlugins < CollectionRenderer
    type           :plugins
    collection_key :plugins
  end
end
