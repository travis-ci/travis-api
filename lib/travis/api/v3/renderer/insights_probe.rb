module Travis::API::V3
  class Renderer::InsightsProbe < ModelRenderer
    representation :standard, :id, :user_id, :user_plugin_id, :test_template_id, :uuid, :uuid_group, :type,
      :notification, :description, :description_link, :test, :base_object_locator, :preconditions, :conditionals,
      :object_key_locator, :active, :editable, :template_type,
      :cruncher_type, :status, :labels, :plugin_type, :plugin_type_name, :plugin_category, :tag_list, :severity
    representation :minimal, :id, :type, :plugin_type, :plugin_type_name, :plugin_category, :label, :notification, :status, :tag_list, :severity
  end
end
