module Travis::API::V3
  module Renderer::SpotlightSummary
    extend self

    AVAILABLE_ATTRIBUTES = [:data]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'spotlight_summary'.freeze,
        data: object.fetch('data'),
      }
    end
  end
end
