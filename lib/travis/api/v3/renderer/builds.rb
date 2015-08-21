module Travis::API::V3
  class Renderer::Builds < Renderer::CollectionRenderer
    type            :builds
    collection_key  :builds
  end
end
