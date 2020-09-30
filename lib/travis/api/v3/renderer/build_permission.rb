module Travis::API::V3
  class Renderer::BuildPermission < ModelRenderer
    representation(:minimal, :user, :permission, :role)
    representation(:standard, :user, :permission, :role)

    def user
      Renderer.render_model(model.user, mode: :minimal)
    end

    def permission
      value = model.respond_to?(:build_permission) ? model.build_permission : model.build
      value.nil? ? true : value
    end

    def role
      model.respond_to?(:role) ? model.role : nil
    end
  end
end
