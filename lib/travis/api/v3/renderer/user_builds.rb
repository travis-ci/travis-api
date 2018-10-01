module Travis::API::V3
  class Renderer::UserBuilds < CollectionRenderer
    type            :builds
    collection_key  :builds
  end
end
