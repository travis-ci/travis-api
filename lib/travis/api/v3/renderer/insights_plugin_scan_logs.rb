module Travis::API::V3
  module Renderer::InsightsPluginScanLogs
    extend self

    AVAILABLE_ATTRIBUTES = [:meta, :scan_logs]

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(object, **)
      {
        '@type': 'insights_plugin_scan_logs'.freeze,
        meta: object.fetch('meta', {}),
        scan_logs: object.fetch('scan_logs', [])
      }
    end
  end
end
