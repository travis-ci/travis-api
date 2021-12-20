module Travis::API::V3
  module Renderer::InsightsSandboxPluginData
    extend self

    AVAILABLE_ATTRIBUTES = [:data]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_sandbox_plugin_data'.freeze,
        data: object
      }
    end
  end
end
