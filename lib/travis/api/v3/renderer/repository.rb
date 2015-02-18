require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Repository < Renderer::ModelRenderer
    representation(:minimal,  :id, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_language, :active, :private, :default_branch, :owner, :last_build)

    def default_branch
      model.default_branch || 'master'.freeze
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
