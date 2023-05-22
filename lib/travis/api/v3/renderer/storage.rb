module Travis::API::V3
  class Renderer::Storage < ModelRenderer
    representation(:standard,:id, :value)

    def id
      model.id.split('::')&.last || id
    end
  end
end
