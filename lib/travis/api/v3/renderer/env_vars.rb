module Travis::API::V3
  class Renderer::EnvVars < CollectionRenderer
    type           :env_vars
    collection_key :env_vars
  end
end
