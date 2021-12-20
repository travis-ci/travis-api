module Travis::API::V3
  module Renderer::InsightsSandboxQueryResult
    extend self

    AVAILABLE_ATTRIBUTES = [:negative_results, :positive_results, :success]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_sandbox_query_result'.freeze,
        negative_results: object['negative_results'],
        positive_results: object['positive_results'],
        success: object['success']
      }
    end
  end
end
