require 'travis/api/v3/renderer/owner'

module Travis::API::V3
  class Renderer::Users < CollectionRenderer
    type           :users
    collection_key :users
  end
end
