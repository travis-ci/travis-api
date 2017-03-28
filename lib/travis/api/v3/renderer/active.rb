module Travis::API::V3
  class Renderer::Active < CollectionRenderer
    type            :builds
    collection_key  :builds

    def representation
      :active
    end
  end
end
