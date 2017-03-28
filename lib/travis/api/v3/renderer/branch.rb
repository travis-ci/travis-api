module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)
  end
end
