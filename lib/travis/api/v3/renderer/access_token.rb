module Travis::API::V3
  module Renderer::AccessToken
    extend self

    def render(payload, **options)
      { :@type => 'access_token'.freeze, token: Renderer.render_value(payload) }
    end
  end
end
