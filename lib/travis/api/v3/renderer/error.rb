module Travis::API::V3
  module Renderer::Error
    AVAILABLE_ATTRIBUTES = [ :error_type, :error_message, :resource_type, :permission ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(error, **)
      {
        :@type         => 'error'.freeze,
        :error_type    => error.type,
        :error_message => error.message,
        **Renderer.render_value(error.payload)
      }
    end
  end
end
