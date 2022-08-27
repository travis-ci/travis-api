module Travis::API::V3
  class Models::InsightsPlugin
    attr_reader :id, :name, :public_id, :plugin_type, :plugin_category, :last_scan_end, :scan_status, :plugin_status, :active

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @name = attributes.fetch('name')
      @public_id = attributes.fetch('public_id')
      @plugin_type = attributes.fetch('plugin_type')
      @plugin_category = attributes.fetch('plugin_category')
      @last_scan_end = attributes.fetch('last_scan_end')
      @scan_status = attributes.fetch('scan_status')
      @plugin_status = attributes.fetch('plugin_status')
      @active = attributes.fetch('active')
    end
  end
end
