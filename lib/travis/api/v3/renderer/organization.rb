module Travis::API::V3
  module Renderer::Organization
    DIRECT_ATTRIBUTES = %i[id login name github_id]
    extend self

    def render(organization, **)
      { :@type => 'organization'.freeze, **direct_attributes(organization) }
    end

    def direct_attributes(repository)
      DIRECT_ATTRIBUTES.map { |a| [a, repository.public_send(a)] }.to_h
    end
  end
end
