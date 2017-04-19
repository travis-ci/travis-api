module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)

    def render(representation)
      super 
    end

    def recent_builds
      return model.builds.first(10) if include_recent_builds?
    end

    def include_recent_builds?
      return true if include?'branch.recent_builds'.freeze
    end
  end
end
