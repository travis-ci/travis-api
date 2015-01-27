module Travis::API::V3
  module Renderer::Repository
    DIRECT_ATTRIBUTES = %i[id name slug description github_language private]
    extend self

    def render(repository)
      { :@type => 'repository'.freeze, active: !!repository.active, **direct_attributes(repository), **nested_resources(repository) }
    end

    def direct_attributes(repository)
      DIRECT_ATTRIBUTES.map { |a| [a, repository.public_send(a)] }.to_h
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
