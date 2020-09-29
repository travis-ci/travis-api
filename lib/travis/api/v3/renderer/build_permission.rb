module Travis::API::V3
  class Renderer::BuildPermission < ModelRenderer
    representation(:minimal, :user, :permission, :role)
    representation(:standard, :user, :permission, :role)

    def user
      Renderer.render_model(model.user, mode: :minimal)
    end
  end
end
