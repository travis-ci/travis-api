module Travis::API::V3
  class Models::InsightsNotification
    attr_reader :id, :type, :active, :weight, :message, :plugin_name, :plugin_type, :plugin_category, :probe_severity, :description, :description_link

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @type = attributes.fetch('type')
      @active = attributes.fetch('active')
      @weight = attributes.fetch('weight')
      @message = attributes.fetch('message')
      @plugin_name = attributes.fetch('plugin_name')
      @plugin_type = attributes.fetch('plugin_type')
      @plugin_category = attributes.fetch('plugin_category')
      @probe_severity = attributes.fetch('probe_severity')
      @description = attributes.fetch('description', '')
      @description_link = attributes.fetch('description_link', '')
    end
  end
end
