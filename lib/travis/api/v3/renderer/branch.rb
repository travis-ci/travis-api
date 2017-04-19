module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)

    def render(representation)
      super unless include?(:recent_builds)
      representation(:standard, :name, :repository, :default_branch, :exists_on_github, :recent_builds)
    end

    def recent_builds
      model.builds.first(10)
    end
  end
end
