module Travis::API::V3
  module Renderer::Lint
    extend self

    def render(payload)
      { Renderer.render_value(payload) }
    end
  end
end
