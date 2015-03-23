module Travis::API::V3
  module Renderer::Accepted
    extend self

    def render(payload, **options)
      { :@type => 'pending'.freeze, **Renderer.render_value(payload) }
    end
  end
end
