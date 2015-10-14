require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Branch < Renderer::ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)
  end
end
