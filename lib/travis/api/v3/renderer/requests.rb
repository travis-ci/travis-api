module Travis::API::V3
  class Renderer::Requests < CollectionRenderer
    type            :requests
    collection_key  :requests

    def self.available_attributes
      [:config, :message, :branch, :token]
    end
  end
end
