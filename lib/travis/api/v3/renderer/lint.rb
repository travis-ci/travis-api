module Travis::API::V3
  module Renderer::Lint
    AVAILABLE_ATTRIBUTES = [ :warnings ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(lint, **)
      {
        :@type       => 'lint'.freeze,
        :warnings    => warnings_for(lint)
      }
    end

    def warnings_for(lint)
      lint.nested_warnings.map { |k, m| { key: k, message: m } }
    end
  end
end
