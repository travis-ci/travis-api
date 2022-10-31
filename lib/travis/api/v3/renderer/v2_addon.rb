module Travis::API::V3
  class Renderer::V2Addon < ModelRenderer
    representation(:standard, :id, :name, :type, :current_usage, :recurring)
    representation(:minimal, :id, :name, :type, :current_usage, :recurring)

    def current_usage
      Renderer.render_model(model.current_usage, mode: :standard) unless model.current_usage.nil?
    end
  end
end
