module Travis::API::V3
  class Renderer::Cache < Renderer::ModelRenderer
    representation(:minimal,  :repository_id, :size, :slug, :branch, :last_modified)
    representation(:standard, *representations[:minimal], :repo)
  end
end
