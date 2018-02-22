module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)
    representation(:additional, :recent_builds)

    def recent_builds
      if include_recent_builds?
        V3::Models::Build.where(
          event_type: 'push',
          repository_id: model.repository_id,
          branch_id: model.id
        ).order(created_at: :desc).first(10)
      end
    end

    def include_recent_builds?
      return true if include? 'branch.recent_builds'.freeze
    end
  end
end
