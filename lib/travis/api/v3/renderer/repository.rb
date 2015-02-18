require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Repository < Renderer::ModelRenderer
    representation(:minimal,  :id, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_language, :active, :private, :owner, :last_build, :default_branch)

    def default_branch
      branch_name = model.default_branch || 'master'.freeze
      {
        :@type      => 'branch'.freeze,
        :name       => branch_name,
        :last_build => model.last_build_on(branch_name)
      }
    end

    def active
      !!model.active
    end

    def owner
      {
        :@type        => model.owner_type && model.owner_type.downcase,
        :id           => model.owner_id,
        :login        => model.owner_name
      }
    end

    def last_build
      return nil unless model.last_build_id
      {
        :@type        => 'build'.freeze,
        :@href        => Renderer.href(:build, script_name: script_name, id: model.last_build_id),
        :id           => model.last_build_id,
        :number       => model.last_build_number,
        :state        => model.last_build_state.to_s,
        :duration     => model.last_build_duration,
        :started_at   => model.last_build_started_at,
        :finished_at  => model.last_build_finished_at,
      }
    end
  end
end
