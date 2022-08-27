module Travis::API::V3
  module Renderer::InsightsPluginTests
    extend self

    AVAILABLE_ATTRIBUTES = [:template_tests, :plugin_category]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_plugin_tests'.freeze,
        template_tests: object['template_tests'],
        plugin_category: object['plugin_category']
      }
    end
  end
end
