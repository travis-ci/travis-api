module Travis::API::V3
  class Renderer::InsightsTags < CollectionRenderer
    type           :tags
    collection_key :tags
  end
end
