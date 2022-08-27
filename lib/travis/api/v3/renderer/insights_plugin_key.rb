module Travis::API::V3
  module Renderer::InsightsPluginKey
    extend self

    AVAILABLE_ATTRIBUTES = [:keys]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_plugin_key'.freeze,
        keys: object['keys']
      }
    end
  end
end
