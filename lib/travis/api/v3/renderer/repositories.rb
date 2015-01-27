module Travis::API::V3
  module Renderer::Repositories
    extend self

    def render(repositories)
      Renderer[:collection].render(:repositories, :repository, repositories)
    end
  end
end
