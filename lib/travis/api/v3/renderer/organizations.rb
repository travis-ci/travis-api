module Travis::API::V3
  module Renderer::Organizations
    extend self

    def render(repositories)
      Renderer[:collection].render(:organizations, :organization, repositories)
    end
  end
end
