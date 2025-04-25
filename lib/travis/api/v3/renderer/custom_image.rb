module Travis::API::V3
  class Renderer::CustomImage < ModelRenderer
    representation :minimal, :id, :owner_id, :owner_type, :name, :usage, :created_at, :updated_at, :os_version,
                   :created_by, :private, :size_bytes
    representation :standard, *representations[:minimal]

    def created_by
      return nil unless user = model.created_by
      {
        '@type' => 'user',
        '@href' => "/v3/user/#{user.id}",
        '@representation' => 'minimal'.freeze,
        'id' => user.id,
        'login' => user.login,
        'name' => user.name,
        'avatar_url' => user.avatar_url
      }
    end
  end
end
