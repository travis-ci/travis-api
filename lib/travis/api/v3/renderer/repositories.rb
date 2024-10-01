module Travis::API::V3
  class Renderer::Repositories < CollectionRenderer
    type           :repositories
    collection_key :repositories

    def render
      authorizer.cache_repos(list.map(&:id))
      super
    end
  end
end
