module Travis::API::V3
  module Renderer::Organizations
    extend self

    def render(repositories, **options)
      Renderer[:collection].render(:organizations, :organization, repositories, **options)
    end
  end
end
