module Travis::API::V3
  class Renderer::InsightsPlugin < ModelRenderer
    representation :standard, :id, :name, :public_id, :plugin_type, :plugin_category, :last_scan_end, :scan_status, :plugin_status, :active
    representation :minimal, :id, :name, :public_id, :plugin_type, :last_scan_end, :scan_status, :plugin_status, :active
  end
end
