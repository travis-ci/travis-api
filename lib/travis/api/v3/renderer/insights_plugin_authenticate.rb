module Travis::API::V3
  module Renderer::InsightsPluginAuthenticate
    extend self

    AVAILABLE_ATTRIBUTES = [:success, :error_msg]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_plugin_authenticate'.freeze,
        success: object['success'],
        error_msg: object['error_msg']
      }
    end
  end
end
