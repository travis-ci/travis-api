module Travis::API::V3
  module Renderer::InsightsSpotlightSummary
    extend self

    AVAILABLE_ATTRIBUTES = [:data]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_spotlight_summary'.freeze,
        data: object.fetch('data'),
      }
    end
  end
end
