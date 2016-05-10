module Travis::API::V3
  class Renderer::Repositories < Renderer::CollectionRenderer
    type           :repositories
    collection_key :repositories

    def render
      preload
      super
    end

    def preload
      # preload builds that we will need
      current_build_ids = list.map { |r| r[:current_build_id] }.compact
      Travis::API::V3::Models::Build.find(current_build_ids)
    end
  end
end
