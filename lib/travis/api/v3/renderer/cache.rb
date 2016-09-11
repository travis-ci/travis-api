module Travis::API::V3
  class Renderer::Cache < Renderer::ModelRenderer
    representation(:minimal,  :repository_id, :size, :branch, :last_modified)
    representation(:standard, *representations[:minimal], :repo)
  end
end
