module Travis::API::V3
  class Renderer::EnvVars < Renderer::CollectionRenderer
    type           :env_vars
    collection_key :env_vars 
  end
end
