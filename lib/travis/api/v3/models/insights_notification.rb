module Travis::API::V3
  class Models::InsightsNotification
    attr_reader :id, :type, :active, :weight, :message, :plugin_name, :plugin_type, :plugin_category, :probe_severity

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @probe_severity = attributes.fetch('probe_severity')
    end
  end
end
