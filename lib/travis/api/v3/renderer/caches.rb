module Travis::API::V3
  class Renderer::Caches < Renderer::CollectionRenderer
    type            :caches
    collection_key  :caches

    def self.available_attributes
      [:branch, :match]
     end
  end
end
