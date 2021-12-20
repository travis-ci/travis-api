module Travis::API::V3
  class Renderer::InsightsNotification < ModelRenderer
    representation :standard, :id, :type, :active, :weight, :message, :plugin_name, :plugin_type, :plugin_category, :probe_severity
    representation :minimal, :id, :type, :active, :weight, :probe_severity
  end
end
