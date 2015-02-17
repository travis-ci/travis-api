module Travis::API::V3
  module Renderer::Repositories
    extend self

    def render(repositories, **options)
      Renderer[:collection].render(:repositories, :repository, repositories, **options)
    end
  end
end
