require 'travis/api/v3/renderer/collection_renderer'

module Travis::API::V3
  class Renderer::Accounts < Renderer::CollectionRenderer
    type            :accounts
    collection_key  :accounts
  end
end
