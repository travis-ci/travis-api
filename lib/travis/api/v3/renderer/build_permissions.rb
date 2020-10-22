module Travis::API::V3
  class Renderer::BuildPermissions < CollectionRenderer
    type            :build_permissions
    collection_key  :build_permissions

    def render_entry(entry, **options)
      options[:type] = :build_permission
      super
    end
  end
end
