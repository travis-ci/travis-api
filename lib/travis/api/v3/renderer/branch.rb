module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)
    representation(:additional, :recent_builds)

    def recent_builds
      return unless include_recent_builds?
      builds = model.class.includes(:builds_with_limit).where(id: model.id).first.builds_with_limit
      access_control.visible_builds(builds)
    end

    def include_recent_builds?
      return true if include? 'branch.recent_builds'.freeze
    end
  end
end
