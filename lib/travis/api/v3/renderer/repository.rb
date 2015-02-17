module Travis::API::V3
  module Renderer::Repository
    DIRECT_ATTRIBUTES = %i[id name slug description github_language private active default_branch]
    DEFAULTS          = { active: false, default_branch: 'master' }
    extend self

    def render(repository, script_name: nil, **)
      {
        :@type => 'repository'.freeze,
        :@href => Renderer.href(:repository, id: repository.id, script_name: script_name),
        **Renderer.get_attributes(repository, *DIRECT_ATTRIBUTES, **DEFAULTS), **nested_resources(repository)
      }
    end

    def nested_resources(repository)
      {
        owner: {
          :@type        => repository.owner_type && repository.owner_type.downcase,
          :id           => repository.owner_id,
          :login        => repository.owner_name
        },
        last_build: last_build(repository)
      }
    end

    def last_build(repository)
      return nil unless repository.last_build_id
      {
        :@type        => 'build'.freeze,
        :id           => repository.last_build_id,
        :number       => repository.last_build_number,
        :state        => repository.last_build_state.to_s,
        :duration     => repository.last_build_duration,
        :started_at   => Renderer.format_date(repository.last_build_started_at),
        :finished_at  => Renderer.format_date(repository.last_build_finished_at),
      }
    end
  end
end
