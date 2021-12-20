module Travis::API::V3
  class Models::InsightsProbe
    attr_reader :id, :user_id, :user_plugin_id, :test_template_id, :uuid, :uuid_group, :type,
      :notification, :description, :description_link, :test, :base_object_locator, :preconditions, :conditionals,
      :object_key_locator, :active, :editable, :template_type, :cruncher_type, :status, :labels, :plugin_type,
      :plugin_type_name, :plugin_category, :tag_list, :severity

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @user_id = attributes.fetch('user_id')
      @user_plugin_id = attributes.fetch('user_plugin_id')
      @test_template_id = attributes.fetch('test_template_id')
      @uuid = attributes.fetch('uuid')
      @uuid_group = attributes.fetch('uuid_group')
      @type = attributes.fetch('type')
      @notification = attributes.fetch('notification')
      @description = attributes.fetch('description')
      @description_link = attributes.fetch('description_link')
      @test = attributes.fetch('test')
      @base_object_locator = attributes.fetch('base_object_locator')
      @preconditions = attributes.fetch('preconditions')
      @conditionals = attributes.fetch('conditionals')
      @object_key_locator = attributes.fetch('object_key_locator')
      @active = attributes.fetch('active')
      @editable = attributes.fetch('editable')
      @template_type = attributes.fetch('template_type')
      @cruncher_type = attributes.fetch('cruncher_type')
      @status = attributes.fetch('status')
      @labels = attributes.fetch('labels')
      @plugin_type = attributes.fetch('plugin_type')
      @plugin_type_name = attributes.fetch('plugin_type_name')
      @plugin_category = attributes.fetch('plugin_category')
      @tag_list = attributes.fetch('tag_list')
      @severity = attributes.fetch('severity')
    end
  end
end
