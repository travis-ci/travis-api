module Travis::API::V3
  class Renderer::Branch < ModelRenderer
    representation(:minimal, :name)
    representation(:standard, :name, :repository, :default_branch, :exists_on_github, :last_build)
    representation(:additional, :recent_builds)

    def repository
      puts "Oto model.repository: #{model.repository.to_s}"
      Renderer.render_model(model.repository, mode: :standard)
    end

    def recent_builds
      return unless include_recent_builds?
      access_control.visible_builds(model.builds.limit(10))
    end

    def include_recent_builds?
      return true if include? 'branch.recent_builds'.freeze
    end
  end
end
